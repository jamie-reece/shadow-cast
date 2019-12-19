require "feedjira"
require "httparty"
require "nokogiri"
require "pry"
require "cgi"
require "rss"

def remove_html_tags(str)
  re = /<("[^"]*"|'[^']*'|[^'">])*>/
  str.gsub!(re, '')
end

def parse_feed(url)
  # http request to url parameter
  xml = HTTParty.get(url).body
  # parse response w/ feedjira
  feed = Feedjira.parse(xml)
  # parse response w/ nokogiri
  doc = Nokogiri::HTML(HTTParty.get(url).body)
  puts "Parsing '#{doc.title}' at #{url}..."
  # 
    rss_feed = RSS::Parser.parse(open(url))
    # feed_meta = {
    #   feed_owner: (feed.channel.itunes_owner.itunes_name rescue nil),
    #   feed_title: (feed.channel.title rescue nil),
    #   feed_desc: (feed.channel.description rescue nil),
    #   feed_lang: (feed.channel.language rescue nil),
    #   feed_last_built: (feed.channel.lastBuildDate rescue nil),
    #   feed_cvr_img: (feed.channel.itunes_image rescue nil),
    #   feed_category: (feed.channel.itunes_category rescue nil)
    # }
    # create hash with basic feed details and episodes array
    podcast = {
      src: url,
      title: doc.title,
      desc: rss_feed.channel.description,
      cvr_img: rss_feed.channel.itunes_image.href,
      episodes: Array.new
    }
  # iterate over feed, storing each episode in episodes array
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
      thumbnail: entry.itunes_image,
      backup_thumbnail: rss_feed.channel.itunes_image.href
    }
    # store episode in episodes array
    podcast[:episodes].push(episode)
  end
  # return hash to write in next function
  return podcast
end

def fetch
  # init empty array
  data = Array.new
  # iterate over urls from txt doc and pass to function
  File.readlines("./assets/feed-list.txt").each do |line|
    data << parse_feed(line.chomp)
  end
  # write data grouped by podcast to podcasts.json
  File.open("./_data/podcasts.json", "w") do |file|
    file.write(JSON.pretty_generate(data))
  end
  # init empty array
  episodes = Array.new
  # iterate over podcasts and store episodes in a new array
  data.each do |podcast|
    episodes << podcast[:episodes]
  end
  # write all episodes in flat structure to episodes.json
  File.open("./_data/episodes.json", "w") do |file|
    file.write(JSON.pretty_generate(episodes.flatten))
  end
end

fetch

def edit_data(filename)
  # load json from file
  json = JSON.parse(File.read("./_data/#{filename}"))
  # iterate over episodes converting episode pub_date to date type and length to integer
  json = json.each do |episode|
    episode["pub_date"] = Date.parse(episode["pub_date"])
    episode["length"] = episode["length"].to_i
    # episode["desc"] = remove_html_tags(episode["desc"])
  end
  # reverse sort episodes by date published
  json = json.sort_by { |episode| episode["pub_date"] }.reverse
  # rewrite file
  File.open("./_data/episodes.json", "w") do |file|
    file.write(JSON.pretty_generate(json))
  end
end

edit_data("episodes.json")

# def parse_feed(url)
#   xml = HTTParty.get(url).body
#   feed = Feedjira.parse(xml)
#   doc = Nokogiri::HTML(HTTParty.get(url).body)
#   puts "Parsing '#{doc.title}' at #{url}..."
#   podcasts = Array.new
#   podcast = {
#     src: url,
#     title: doc.title
#   }
#   podcasts.push(podcast)
#   File.open("./_data/podcasts.json", "w") do |file|
#     file.write(JSON.pretty_generate(podcasts))
#   end
#   episodes = Array.new
#   feed.entries.each do |entry|
#     episode = {
#       src: url,
#       url: entry.url,
#       feed: doc.title,
#       title: entry.title.strip,
#       author: entry.itunes_author,
#       pub_date: entry.published,
#       desc: entry.summary,
#       audio: entry.enclosure_url,
#       duration: entry.itunes_duration,
#       length: entry.enclosure_length,
#       type: entry.enclosure_type,
#       thumbnail: entry.itunes_image
#     }
#     episodes.push(episode)
#   end
#   podcast.store("episodes", episodes)
#   puts "#{episodes.length} episodes found"
#   # return podcast
# end

# parse_feed("https://goldenharebooks.com/feed/podcast/")

# def process_data
#   data = Array.new
#   data << parse_feed("https://goldenharebooks.com/feed/podcast/")
#   data << parse_feed("https://feeds.soundcloud.com/users/soundcloud:users:13730980/sounds.rss")
#   # data << parse_feed("https://feeds.soundcloud.com/users/soundcloud:users:14268499/sounds.rss")
#   # data << parse_feed("https://rss.acast.com/vintagepodcast")
#   # data << parse_feed("https://feeds.soundcloud.com/users/soundcloud:users:8180342/sounds.rss")
#   # data << parse_feed("https://www.theguardian.com/books/series/books/podcast.xml")
#   # data << parse_feed("https://feeds.soundcloud.com/users/soundcloud:users:313878848/sounds.rss")
#   # data << parse_feed("https://rss.acast.com/readlikeawriter")
#   # data << parse_feed("https://independentpublishersguild.libsyn.com/rss")
#   # data << parse_feed("https://feed.pippa.io/public/shows/5ce3bd97862700d1704d3dfb")
#   # data << parse_feed("https://feeds.soundcloud.com/users/soundcloud:users:47550828/sounds.rss")
#   # data << parse_feed("https://feeds.soundcloud.com/users/soundcloud:users:535574250/sounds.rss")
#   # data << parse_feed("https://feeds.fireside.fm/verybadwizards/rss")
#   # data << parse_feed("https://rss.acast.com/londonreviewpodcasts")
#   # data << parse_feed("https://feeds.soundcloud.com/users/soundcloud:users:1076867/sounds.rss")
#   # puts "#{data.length} feeds parsed for #{data.flatten.length} episodes"
#   File.open("./_data/podcasts.json", "w") do |file|
#     file.write(JSON.pretty_generate(data))
#   end
# end

# process_data
