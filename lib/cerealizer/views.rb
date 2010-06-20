module Cerealizer
  module Views
    def self.domain_example(d,filename)
      open(filename, 'w') do |f|
        f.puts("<html><body><ol>")
        (1..10000).each do |n|
          f.puts("<li><pre>" + d.from_n(n).to_s.gsub("<","&lt;") + "</pre></li>")
        end
        f.puts("</ol></body></html>")
      end
    end
  end
end
