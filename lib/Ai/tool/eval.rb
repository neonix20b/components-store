# frozen_string_literal: true

module Ai::Tool
  #
  # A calculator tool that falls back to the Google calculator widget
  #
  # Gem requirements:
  #     gem "eqn", "~> 1.6.5"
  #     gem "google_search_results", "~> 2.0.0"
  #
  # Usage:
  #     calculator = Ai::Tool::Calculator.new
  #
  class Eval
    extend Ai::ToolDefinition
    include Ai::DependencyHelper

    define_function :ruby, description: "Выполнить код на ruby" do
      property :input, type: "string", description: "Исходный код на ruby", required: true
    end

    def ruby(input:)
      puts("Executing \"#{input}\"")
      eval(input)
    end
  end
end