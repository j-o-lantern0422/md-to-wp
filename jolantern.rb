require "yaml"
require "pathname"
require "tempfile"

class Jolantern

  def symbolize_keys(hash)
    hash.map{|k,v| [k.to_sym, v] }.to_h
  end

  # マークダウンの先頭にあるメタ情報を取得する
  def article_metadata(markdown_path)
    header_elementes = %w(
      title
      subtitle
      description
      date
      author
      image
      type
      tag
      tags
      featured_tags
      categories
      url
      draft
    )

    markdown = File.open(markdown_path, "r")
    
    header_flg = false
    header_yaml = ""
    markdown.each_with_index do | line, index |
      if index == 0
        header_flg = true
        next
      elsif line == "---\n"
        break
      end

      header_yaml << line
    end
    
    symbolize_keys(YAML.load(header_yaml))
  end

  def remove_metadata(markdown_path)
    markdown = File.open(markdown_path, "r")
    metadata_flg = false
    removed_article = ""
    
    markdown.each_with_index do | line, index |
      if metadata_flg && line != "---\n"
        next
      end

      if index == 0
        metadata_flg = true
        next
      elsif line == "---\n"
        metadata_flg = false
      end
      removed_article << line
    end

    removed_article
  end

  def remove_unnecessary_elementes(article)
    unnecessary_elementes = [
      "<code>",
      "</code>",
      "<code class=\"ruby\">",
      "<code class=\"shell\">",
      "<code class=\"yml\">",
      "<code class=\"sh\">",
      "<code class=\"html\">",
      "<code class=\"json\">",
    ]

    parsed = ""
    article.each do | line |
      unnecessary_elementes.each do | element |
        line.gsub!(element, "")
      end
      parsed << line
    end

    parsed
  end

  def parse_article(markdown_path)

    metadata_removed_file = Tempfile.create("metadata_removed_file")    
    metadata_removed_file.puts(remove_metadata(markdown_path))
    metadata_removed_file.rewind

    unnecessary_elementes_removed_file = Tempfile.create("unnecessary_elementes_removed_file")  
    unnecessary_elementes_removed_file.puts(remove_unnecessary_elementes(metadata_removed_file))
    unnecessary_elementes_removed_file.rewind
    
    unnecessary_elementes_removed_file.read
  end

  def parse_articles
    contents_filepath = "./contents"
    parsed_contents = []
    Dir.foreach(contents_filepath) do | item |
      next if item == '.' or item == '..'

      if File.extname(item) != ".md"
        puts "マークダウンではなさそう:#{File.basename(item)}"
        
        next
      end

      markdown_path = Pathname(contents_filepath).join(item)
      metadata = article_metadata(markdown_path)
      article = parse_article(markdown_path)

      
      parsed_contents.push({ metadata: metadata, article: article, filename: item })
    end

    parsed_contents
  end
end

