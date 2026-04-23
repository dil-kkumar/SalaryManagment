# frozen_string_literal: true

module Api
  module V1
    class CountryCustomFieldsController < ApplicationController
      before_action :set_country_custom_field, only: %i[update destroy]

      def index
        render json: serialize_collection(CountryCustomField.ordered)
      end

      def create
        field = CountryCustomField.create!(country_custom_field_params)
        render json: serialize_field(field), status: :created
      end

      def update
        @country_custom_field.update!(country_custom_field_params)
        render json: serialize_field(@country_custom_field)
      end

      def destroy
        @country_custom_field.destroy!
        head :no_content
      end

      private

      def set_country_custom_field
        @country_custom_field = CountryCustomField.find(params[:id])
      end

      def country_custom_field_params
        params.require(:country_custom_field).permit(:country, :field_key, :label, :field_type, :placeholder, :required)
      end

      def serialize_field(field)
        field.as_json(only: %i[id country field_key label field_type placeholder required created_at updated_at])
      end

      def serialize_collection(collection)
        collection.as_json(only: %i[id country field_key label field_type placeholder required created_at updated_at])
      end
    end
  end
end