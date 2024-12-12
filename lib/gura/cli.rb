require "gura"
require "thor"
require_relative "../img/img"

module Gura
  class CLI < Thor
    desc 'create --model {model} --zoom {max_zoom} --size {image size}', 'Generate Gura image'
    option :model
    option :zoom
    option :size
    def create()
      model = options[:model] || "gura"
      zoom = options[:zoom] || 1
      size = options[:size] || 256
      font_size = 12
      left_longitude = 0
      total_longitude_range = 360.0
      puts "Generating Gura image with model: #{model}, zoom: #{zoom}, size: #{size}"
      m = Img::Img.new
      puts "m is #{m}"
      dir_name = "tiles"
      m.create(size, zoom, size, dir_name, font_size, left_longitude, total_longitude_range)
    end

    no_commands do
      def self.exit_on_failure?
        true
      end
    end
  end
end

