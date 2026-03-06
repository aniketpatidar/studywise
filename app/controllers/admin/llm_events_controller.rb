module Admin
  class LlmEventsController < ApplicationController
    def show
      @event = policy_scope(LlmEvent).find(params[:id])
      authorize @event
    end
  end
end
