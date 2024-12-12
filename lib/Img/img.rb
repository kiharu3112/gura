require 'rmagick'
require 'fileutils'
module Img
  # 緯度系経度からピクセル座標への変換関数(タイル座標系)
  class Img
    # 緯度経度からピクセル座標への変換関数(タイル座標系)
    def lat_lon_to_tile_pixels(lat, lon, zoom, x_tile, y_tile, left_lon, total_lon_range)
      tile_size = 256
      n = 2.0 ** zoom
      lon_per_tile = total_lon_range / n

      x_total = ((lon - left_lon) / total_lon_range) * n * tile_size
      lat_rad = lat * Math::PI / 180
      y_total = ((1.0 - Math.log(Math.tan(lat_rad) + 1 / Math.cos(lat_rad)) / Math::PI) / 2.0) * n * tile_size

      x = x_total - x_tile * tile_size
      y = y_total - y_tile * tile_size
      [x, y]
    end

    def create(img_size, max_zoom, tile_size, dir_name = "tiles", font_size = 12, left_longitude = 0, total_longitude_range = 360.0)
      puts "max_zoom is #{max_zoom}"
      (0..max_zoom.to_i).each do |zoom|
        num_tiles = 2**zoom

        # 線の間隔をズームレベルに応じて調整
        lon_step = case zoom
                   when 0 then 30
                   when 1 then 20
                   when 2 then 10
                   when 3 then 5
                   else 2
                   end

        lat_step = lon_step

        font_size = 12  # フォントサイズ（必要に応じて調整可能）

        num_tiles.times do |x|
          num_tiles.times do |y|
            # Y 座標を反転（タイル座標系に合わせるため）
            y_flip = (num_tiles - 1) - y

            # タイル画像を作成
            image = Magick::Image.new(tile_size.to_i, tile_size.to_i) do |c|
              c.background_color = 'transparent' # 背景を透明に設定
            end

            draw = Magick::Draw.new
            draw.stroke('black')
            draw.stroke_width(1)
            draw.fill('black')
            draw.pointsize = font_size

            # タイルの経度・緯度の範囲を計算
            lon_min = left_longitude + (x.to_f / num_tiles) * total_longitude_range
            lon_max = left_longitude + ((x + 1).to_f / num_tiles) * total_longitude_range
            lat_max = 90.0 - (y.to_f / num_tiles) * 180.0
            lat_min = 90.0 - ((y + 1).to_f / num_tiles) * 180.0

            # 経線（縦線）の描画と経度ラベルの追加
            (lon_min.to_i..lon_max.to_i).step(lon_step) do |lon|
              x1, y1 = lat_lon_to_tile_pixels(lat_min, lon, zoom, x, y, left_longitude, total_longitude_range)
              x2, y2 = lat_lon_to_tile_pixels(lat_max, lon, zoom, x, y, left_longitude, total_longitude_range)
              if (0..tile_size.to_i).cover?(x1)
                draw.line(x1, 0, x1, tile_size.to_i)
                draw.text(x1 + 2, font_size, "#{lon}°")
              end
            end

            # 緯線（横線）の描画と緯度ラベルの追加
            (lat_min.to_i..lat_max.to_i).step(lat_step) do |lat|
              x1, y1 = lat_lon_to_tile_pixels(lat, lon_min, zoom, x, y, left_longitude, total_longitude_range)
              x2, y2 = lat_lon_to_tile_pixels(lat, lon_max, zoom, x, y, left_longitude, total_longitude_range)
              if (0..tile_size.to_i).cover?(y1)
                draw.line(0, y1, tile_size, y1)
                draw.text(2, y1 - 2, "#{lat}°")
              end
            end

            # 描画を画像に適用
            draw.draw(image)

            # ディレクトリを作成
            dir_path = "#{dir_name}/#{zoom}/#{x}"
            FileUtils.mkdir_p(dir_path)

            # タイルを保存
            image.write("#{dir_path}/#{y_flip}.png")
          end
        end

        puts "ズームレベル #{zoom} のタイル生成が完了しました。"
      end
    end
  end
end
