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

    define_function :ruby, description: "Выполнить код на ruby, возвращаемое значение - результат вычисления последней строки" do
      property :input, type: "string", description: "Исходный код на ruby", required: true
    end

    define_function :sh, description: "Выполнить sh-команду и получить ее результат (stdout + stderr)" do
      property :input, type: "string", description: "Исходная команда", required: true
    end

    def ruby(input:)
      puts("Executing ruby: \"#{input}\"")
      eval(input)
    end

    def sh(input:)
      puts("Executing sh: \"#{input}\"")
      stdout_and_stderr_s, _ = Open3.capture2e(input)
      return stdout_and_stderr_s
    end
  end
end