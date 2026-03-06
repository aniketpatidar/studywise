module Study
  module GenerationTracker
    module_function

    NOTE_LOCK_TTL = 20.minutes
    QUIZ_LOCK_TTL = 10.minutes
    IDEMPOTENCY_TTL = 6.hours
    ERROR_TTL = 1.hour

    def start_note_generation(material_id:, idempotency_key:)
      return :invalid if idempotency_key.blank?
      return :duplicate if idempotency_seen?(:note, material_id, idempotency_key)
      return :in_progress unless acquire_lock(note_lock_key(material_id), NOTE_LOCK_TTL)

      remember_idempotency!(:note, material_id, idempotency_key)
      clear_note_error!(material_id)
      :started
    end

    def finish_note_generation(material_id:)
      release_lock(note_lock_key(material_id))
    end

    def fail_note_generation(material_id:, error_message:)
      release_lock(note_lock_key(material_id))
      write_error(note_error_key(material_id), error_message)
    end

    def note_in_progress?(material_id)
      lock_held?(note_lock_key(material_id))
    end

    def note_error(material_id)
      Rails.cache.read(note_error_key(material_id)).to_s.presence
    end

    def clear_note_error!(material_id)
      Rails.cache.delete(note_error_key(material_id))
    end

    def start_quiz_generation(material_id:, idempotency_key:)
      return :invalid if idempotency_key.blank?
      return :duplicate if idempotency_seen?(:quiz, material_id, idempotency_key)
      return :in_progress unless acquire_lock(quiz_lock_key(material_id), QUIZ_LOCK_TTL)

      remember_idempotency!(:quiz, material_id, idempotency_key)
      clear_quiz_error!(material_id)
      :started
    end

    def finish_quiz_generation(material_id:)
      release_lock(quiz_lock_key(material_id))
    end

    def fail_quiz_generation(material_id:, error_message:)
      release_lock(quiz_lock_key(material_id))
      write_error(quiz_error_key(material_id), error_message)
    end

    def quiz_in_progress?(material_id)
      lock_held?(quiz_lock_key(material_id))
    end

    def quiz_error(material_id)
      Rails.cache.read(quiz_error_key(material_id)).to_s.presence
    end

    def clear_quiz_error!(material_id)
      Rails.cache.delete(quiz_error_key(material_id))
    end

    def note_lock_key(material_id)
      "gen:note:lock:m#{material_id}"
    end

    def quiz_lock_key(material_id)
      "gen:quiz:lock:m#{material_id}"
    end

    def note_error_key(material_id)
      "gen:note:error:m#{material_id}"
    end

    def quiz_error_key(material_id)
      "gen:quiz:error:m#{material_id}"
    end

    def idempotency_key(type, material_id, idempotency_key)
      "gen:#{type}:idem:m#{material_id}:#{idempotency_key}"
    end

    def idempotency_seen?(type, material_id, idempotency_key)
      Rails.cache.exist?(idempotency_key(type, material_id, idempotency_key))
    end

    def remember_idempotency!(type, material_id, idempotency_key)
      Rails.cache.write(idempotency_key(type, material_id, idempotency_key), true, expires_in: IDEMPOTENCY_TTL)
    end

    def acquire_lock(key, ttl)
      Rails.cache.write(key, true, unless_exist: true, expires_in: ttl)
    rescue ArgumentError
      if Rails.cache.read(key)
        false
      else
        Rails.cache.write(key, true, expires_in: ttl)
        true
      end
    end

    def release_lock(key)
      Rails.cache.delete(key)
    end

    def lock_held?(key)
      Rails.cache.read(key).present?
    end

    def write_error(key, error_message)
      message = error_message.to_s.strip
      return if message.blank?

      Rails.cache.write(key, message.first(240), expires_in: ERROR_TTL)
    end
  end
end
