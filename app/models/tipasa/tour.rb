module Tipasa
  # A tour is one YAML file in Tipasa.tours_path; its slug is the file name.
  class Tour
    SLUG = /\A[\w-]+\z/

    attr_reader :slug

    def self.all
      Dir[File.join(Tipasa.tours_path, "*.yml")].sort.map { |path| new(File.basename(path, ".yml"), path) }
    end

    # The slug comes from the URL, so anything that isn't a plain file name is rejected before touching the disk.
    def self.find(slug)
      path = File.join(Tipasa.tours_path, "#{slug}.yml")
      new(slug, path) if slug.to_s.match?(SLUG) && File.file?(path)
    end

    def initialize(slug, path)
      @slug = slug
      @data = YAML.safe_load_file(path) || {}
    end

    def name = @data["name"]
    def description = @data["description"]
    def steps = @data["steps"] || []
    def active? = @data.fetch("active", true)

    # Without `for:` everyone sees the tour, signed in or not. With it, only those owner classes do.
    def visible_to?(owner)
      audience = Array(@data["for"])
      return true if audience.empty?

      audience.any? { |name| (klass = name.to_s.safe_constantize) && owner.is_a?(klass) }
    end

    def as_json(*)
      { slug:, name:, description:, steps: }
    end
  end
end
