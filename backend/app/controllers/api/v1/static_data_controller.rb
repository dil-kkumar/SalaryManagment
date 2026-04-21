# frozen_string_literal: true

module Api
  module V1
    class StaticDataController < ApplicationController
      def index
        render json: StaticDataQuery.new.call
      end
    end
  end
end
