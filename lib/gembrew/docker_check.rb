require 'shellwords'
require 'gembrew/docker_runner'
require 'gembrew/error'

module Gembrew
  class DockerCheck
    def initialize(runner: DockerRunner.new)
      @runner = runner
    end

    def call(formula)
      success = runner.call 'bash', '-euc', script(formula)
      raise Error, 'Homebrew checks failed' unless success

      true
    end

  private

    attr_reader :runner

    def script(formula)
      formula = Shellwords.escape formula
      <<~BASH
        caption() { printf '\\n\\033[1;34m==> gembrew: %s\\033[0m\\n' "$1"; }
        formula=#{formula}
        caption "styling $formula"
        brew style "$formula"
        caption "auditing $formula"
        brew audit --new --online "$formula"
        caption "installing $formula"
        brew install --build-from-source "$formula"
        caption "testing $formula"
        brew test "$formula"
      BASH
    end
  end
end
