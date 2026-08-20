require 'colsole'

module Gembrew
  class Reporter
    include Colsole

    LABELS = {
      rubygems_cache: ['g', 'RubyGems cache'],
      gembrew_cache:  ['g', 'Gembrew cache'],
      downloading:    %w[y Downloading],
    }.freeze

    def archive(state, name, version, index: nil, total: nil)
      color, label = LABELS.fetch state
      parts = []
      parts << counter(index, total) if index && total
      parts << "#{color}`#{label.ljust label_width}`"
      parts << ["nb`#{name}`", version&.to_s].compact.join(' ')
      say parts.join('  ')
    end

    def resolving(name, version)
      say "Resolving dependencies for nb`#{name}` #{version}..."
    end

    def collecting(count)
      say "Collecting nb`#{count}` resources..."
    end

  private

    def counter(index, total)
      "%#{total.to_s.length}d/%d" % [index, total]
    end

    def label_width
      @label_width ||= LABELS.values.map { |_color, label| label.length }.max
    end
  end
end
