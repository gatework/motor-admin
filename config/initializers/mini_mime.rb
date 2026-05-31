# frozen_string_literal: true

# MiniMime 查询补丁，把 MIME 数据文件缓存为 Hash，减少重复线性扫描。
module MiniMime
  class Db
    class RandomAccessDb
      # 使用预构建 Hash 查询 MIME 行，避免每次线性扫描数据文件。
      def lookup(val)
        row = lookup_cache[val.to_s.downcase]

        return unless row

        MiniMime::Info.new(row)
      end

      private

      # 懒加载并缓存 MIME 数据文件，使用 mutex 保证并发下只构建一次。
      def lookup_cache
        return @cache_hash if defined?(@cache_hash)

        @cache_mutex ||= Mutex.new
        @cache_mutex.synchronize do
          @cache_hash ||= File.binread(@path).each_line.index_by { |row| row[/\A[^\s]+/] }
        end
      end
    end
  end
end
