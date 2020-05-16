require "redcarpet"
require "rubypress"
require "date"
require "dotenv"

require_relative './jolantern.rb'

require "byebug"

class MarkdownToWordpress
  def initialize
    Dotenv.load
    @md_parser = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
    @wp = Rubypress::Client.new(
      host: "localhost",
      port: 8080,
      username: ENV["WP_USER_NAME"],
      password: ENV["WP_USER_PASS"]
    )
  end

  def md_to_html(markdown)
    @md_parser.render(markdown)
  end

  def post_wp(title:, date:, post_path:, html:, tags:, categories:)
    terms_names = {}
    unless categories.empty? 
      terms_names[:category] = categories
    end

    unless tags.empty?
      terms_names[:post_tag] = tags
    end

    content = {
      post_status: "publish",
      post_date: date,
      post_content: html,
      post_title: title,
      post_name: post_path,
      post_author: 1,
    }

    @wp.newPost(
      blog_id: 0,
      content: content.merge({terms_names: terms_names})
    )
  end

  def file_path_to_uri(file_path)
    uri_dir_path = file_path.gsub(/.md/, "").split("-")[(0..2)].join("/")

    begin
      Date.parse(uri_dir_path.split("/").join)
    rescue => e
      return File.basename(file_path, ".*")
    end

    basename = File.basename(file_path, ".*")
    uri_last_path = File.basename(file_path, ".*").split("-")[3..-1].join("-")

    "#{uri_dir_path}/#{uri_last_path}"
  end

  def post_all_articles
    j = Jolantern.new
    j.parse_articles.each do | article |
      metadata = article[:metadata]
      path = metadata[:url] || file_path_to_uri(article[:filename])
      if path.nil?
        puts("ファイルパスが設定できない")
      end

      html = md_to_html(article[:article])
      post_wp(  
        title: metadata[:title],
        date: metadata[:date],
        tags: metadata[:tags] || [],
        categories: metadata[:categories] || [],
        html: html,
        post_path: path
      )
    end
  end
end

MarkdownToWordpress.new.post_all_articles