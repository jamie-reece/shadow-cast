require "feedjira"
require "httparty"
require "nokogiri"
require "pry"
require "cgi"

def remove_html_tags(str)
  re = /<("[^"]*"|'[^']*'|[^'">])*>/
  str.gsub!(re, '')
end

def parse_feed(url)
  xml = HTTParty.get(url).body
  feed = Feedjira.parse(xml)
  doc = Nokogiri::HTML(HTTParty.get(url).body)
  puts "Parsing '#{doc.title}' at #{url}..."
  episodes = Array.new
  feed.entries.each do |entry|
    episode = {
      src: url,
      url: entry.url,
      feed: doc.title,
      title: entry.title.strip,
      author: entry.itunes_author,
      pub_date: entry.published,
      desc: entry.summary,
      audio: entry.enclosure_url,
      duration: entry.itunes_duration,
      length: entry.enclosure_length,
      type: entry.enclosure_type,
      thumbnail: entry.itunes_image
    }
    episodes.push(episode)
  end
  puts "#{episodes.length} episodes found"
  return episodes
end

def process_data
  data = Array.new
  data << parse_feed("https://goldenharebooks.com/feed/podcast/")
  data << parse_feed("https://feeds.soundcloud.com/users/soundcloud:users:13730980/sounds.rss")
  data << parse_feed("https://feeds.soundcloud.com/users/soundcloud:users:14268499/sounds.rss")
  data << parse_feed("https://rss.acast.com/vintagepodcast")
  data << parse_feed("https://feeds.soundcloud.com/users/soundcloud:users:8180342/sounds.rss")
  data << parse_feed("https://www.theguardian.com/books/series/books/podcast.xml")
  data << parse_feed("https://feeds.soundcloud.com/users/soundcloud:users:313878848/sounds.rss")
  data << parse_feed("https://rss.acast.com/readlikeawriter")
  data << parse_feed("https://independentpublishersguild.libsyn.com/rss")
  data << parse_feed("https://feed.pippa.io/public/shows/5ce3bd97862700d1704d3dfb")
  data << parse_feed("https://feeds.soundcloud.com/users/soundcloud:users:47550828/sounds.rss")
  data << parse_feed("https://feeds.soundcloud.com/users/soundcloud:users:535574250/sounds.rss")
  data << parse_feed("https://feeds.fireside.fm/verybadwizards/rss")
  data << parse_feed("https://rss.acast.com/londonreviewpodcasts")
  data << parse_feed("https://feeds.soundcloud.com/users/soundcloud:users:1076867/sounds.rss")
  puts "#{data.length} feeds parsed for #{data.flatten.length} episodes"
  File.open("./_data/episodes.json", "w") do |file|
    file.write(JSON.pretty_generate(data.flatten))
  end
end

process_data

def edit_data(filename)
  json = JSON.parse(File.read("./_data/#{filename}"))
  json = json.each do |episode|
    episode["pub_date"] = Date.parse(episode["pub_date"])
    episode["length"] = episode["length"].to_i
    # episode["desc"] = remove_html_tags(episode["desc"])
  end
  json = json.sort_by { |episode| episode["pub_date"] }.reverse
  File.open("./_data/episodes.json", "w") do |file|
    file.write(JSON.pretty_generate(json))
  end
end

edit_data("episodes.json")