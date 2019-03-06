# coding: utf-8


class Tag

  def self.build_breadcrumb_item(level, &block)
    this = ""
    this << Tag.build("li") do |item_tag|
      item_tag["itemscope"] = "itemscope"
      item_tag["itemprop"] = "itemListElement"
      item_tag["itemtype"] = "https://schema.org/ListItem"
      item_tag << Tag.build("a") do |link_tag|
        link_tag["itemprop"] = "item"
        link_tag["itemtype"] = "https://schema.org/Thing"
        link_tag << Tag.build("span") do |name_tag|
          name_tag["itemprop"] = "name"
          block&.call(item_tag, link_tag, name_tag)
        end
      end
      item_tag << Tag.build("meta", nil, false) do |meta_tag|
        meta_tag["itemprop"] = "position"
        meta_tag["content"] = level.to_s
      end
    end
    return this
  end

end