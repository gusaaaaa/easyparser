require 'nokogiri'

class ParserNode

  module Types
    SOMETHING = 0
    BUT       = 1
    MANY      = 2
    TAG       = 3
    TEXT      = 4
    REGEX     = 5
    SCOPE     = 6
    VARIABLE  = 7
    EITHER    = 8
    OR        = 9
  end

  attr_reader :type, :value, :child, :next

  def initialize(type, value, child, next_sibling)
    @type = type
    @value = value
    @child = child
    @next = next_sibling
  end

end

class ParserResult
  attr_reader :valid, :partial, :tail, :ans

  def initialize(args)
    @valid = false
    @partial = false
    @tail = nil
    @ans = nil

    args.each do |k, v|
      instance_variable_set("@#{k}", v) unless v.nil?
    end
  end

  def valid?
    @valid
  end

  def partial?
    @partial
  end

end

class ScopeChain

  def initialize
    @scope_chain = Array.new(1) { Hash.new }
  end

  # TODO: This method should be private or something
  def self.new_from_array(array)
    instance = allocate
    instance.instance_variable_set(:@scope_chain, array)
    instance
  end

  def clone
    ScopeChain.new_from_array @scope_chain.map { |scope| scope.clone }
  end

  def <<(scope)
    # scope is a Hash
    @scope_chain << scope.clone
    self
  end

  def last
    # returns the last scope
    @scope_chain.last.clone
  end

  def [](key)
    recursive_lookup @scope_chain, key
  end

  def []=(key, value)
    @scope_chain.last[key] = value
  end

  def merge!(new_scope_chain)
    @scope_chain.last.merge! new_scope_chain.last
  end

  private

  def recursive_lookup(stack, key)
    if stack.empty?
      nil
    elsif stack.last.has_key?(key)
      stack.last[key]
    else
      recursive_lookup(stack[0..-2], key)
    end
  end
end

# TODO: I don't like monkey patching Proc. Let's find another way. From: http://mattsears.com/articles/2011/11/27/ruby-blocks-as-dynamic-callbacks
class Proc
  def callback(callable, *args)
    self === Class.new do
      method_name = callable.to_sym
      define_method(method_name) { |&block| block.nil? ? true : block.call(*args) }
      define_method("#{method_name}?") { true }
      def method_missing(method_name, *args, &block) false; end
    end.new
  end
end

class EasyParser
  def initialize(ep_source, &block)
    html_source = translate_to_html(ep_source)
    @parse_tree = parse(html_source)
    @callback = block
  end

  def run(html_source, charset = 'ASCII-8BIT', encoding = 'utf-8')
    html_doc = Nokogiri::HTML html_source, nil, charset
    html_doc.encoding = encoding
    html_doc.xpath('//comment()').remove # Remove comments from the HTML document

    #TODO: Must be a better way to do this...
    if @callback
      execute(@parse_tree, html_doc.root, ScopeChain.new, &@callback)
    else
      execute(@parse_tree, html_doc.root, ScopeChain.new)
    end
  end

  private

  def parse(source)
    html_doc = Nokogiri::HTML source
    parse_tree = build_parse_tree(html_doc.root)
  end

  #TODO: Move to helper class
  def child_node(html_node)
    # Hack to prevent reading empty text nodes
    child = html_node.child
    is_empty = ( !child.nil? ) && child.text? && child.text.gsub(/[\r\n\s]/, '').empty?
    while is_empty
      child = child.next
      is_empty = ( !child.nil? ) && child.text? && child.text.gsub(/[\r\n\s]/, '').empty?
    end
    child
  end

  #TODO: Move to helper class
  def next_node(html_node)
    # Hack to prevent reading empty text nodes
    next_node = html_node.next
    is_empty = ( !next_node.nil? ) && next_node.text? && next_node.text.gsub(/[\r\n\s]/, '').empty?
    while is_empty
      next_node = next_node.next
      is_empty = ( !next_node.nil? ) && next_node.text? && next_node.text.gsub(/[\r\n\s]/, '').empty?
    end
    next_node
  end

  #TODO: Naive approach. Find a more robust solution.
  def translate_to_html(ep_source)
    ep_source
      .gsub(/\{many\}/, '<ep-many>')
      .gsub(/\{\/many\}/, '</ep-many>')
      .gsub(/\{\.\.\.\}/, '<ep-something />')
      .gsub(/\{scope\}/, '<ep-scope>')
      .gsub(/\{\/scope\}/, '</ep-scope>')
      .gsub(/\{\$([a-z]+\w*)\}/, '<ep-variable name="\1">')
      .gsub(/\{\/\$[a-z]+\w*\}/, '</ep-variable>')
      .gsub(/\{\/([^\}]+)\/\}/, '<ep-regex value="\1" />')
      .gsub(/\{\.\.\.but\}/, '<ep-but>')
      .gsub(/\{\/\.\.\.but\}/, '</ep-but>')
      .gsub(/\{either\}/, '<ep-either>')
      .gsub(/\{\/either\}/, '</ep-either>')
      .gsub(/\{or\}/, '<ep-or />')
  end

  def build_parse_tree(html_node)
    parse_tree = nil

    if html_node.nil?
      parse_tree = nil
    elsif html_node.text?
      #TODO: Throw error if html_node.children is not empty
      parse_tree = ParserNode.new ParserNode::Types::TEXT, html_node.text, nil, build_parse_tree(next_node(html_node))
    else
      #TODO: Deserves a refactoring
      case html_node.name
        when 'ep-something'
          #TODO: Throw error if html_node.children is not empty
          parse_tree = ParserNode.new ParserNode::Types::SOMETHING, '', nil, build_parse_tree(next_node(html_node))
        when 'ep-but'
          parse_tree = ParserNode.new ParserNode::Types::BUT, '', build_parse_tree(child_node(html_node)), build_parse_tree(next_node(html_node))
        when 'ep-many'
          parse_tree = ParserNode.new ParserNode::Types::MANY, '', build_parse_tree(child_node(html_node)), build_parse_tree(next_node(html_node))
        when 'ep-regex'
          #TODO: Throw error if html_node.children is not empty
          parse_tree = ParserNode.new ParserNode::Types::REGEX, /#{html_node.attr('value')}/, nil, build_parse_tree(next_node(html_node))
        when 'ep-scope'
          parse_tree = ParserNode.new ParserNode::Types::SCOPE, '', build_parse_tree(child_node(html_node)), build_parse_tree(next_node(html_node))
        when 'ep-variable'
          parse_tree = ParserNode.new ParserNode::Types::VARIABLE, html_node.attr('name'), build_parse_tree(child_node(html_node)), build_parse_tree(next_node(html_node))
        when 'ep-either'
          parse_tree = ParserNode.new ParserNode::Types::EITHER, '', build_parse_tree(child_node(html_node)), build_parse_tree(next_node(html_node))
        when 'ep-or'
          parse_tree = ParserNode.new ParserNode::Types::OR, '', nil, build_parse_tree(next_node(html_node))
        else
          # it's a tag
          parse_tree = ParserNode.new ParserNode::Types::TAG, html_node.name, build_parse_tree(child_node(html_node)), build_parse_tree(next_node(html_node))
      end
    end

    parse_tree
  end

  def execute(parser_node, html_node, scope_chain, &block)
    # TODO: Please refactor me!
    scope_chain = scope_chain.clone
    if parser_node.nil? or html_node.nil?
      if parser_node.nil? and html_node.nil?
        result = ParserResult.new valid: true
      elsif html_node.nil?
        if parser_node.type == ParserNode::Types::SOMETHING
          # {...} evaluating nil should be valid
          # {...}<p></p> evaluating nil should not be valid
          result, new_scope_chain = execute(parser_node.next, nil, scope_chain, &block)
          if result.valid?
            result = ParserResult.new valid: true
          else
            result = ParserResult.new valid: false
          end
        elsif parser_node.type == ParserNode::Types::BUT
          # {...but}{/...but} evaluating nil should be valid
          # {...but}{/...but}<p></p> evaluating nil should not be valid
          result, new_scope_chain = execute(parser_node.next, nil, scope_chain, &block)
          if result.valid?
            result = ParserResult.new valid: true
          else
            result = ParserResult.new valid: false
          end
        elsif parser_node.type == ParserNode::Types::OR
          # {or} always evaluates to true
          result = ParserResult.new valid: true
        elsif parser_node.type == ParserNode::Types::REGEX
          if parser_node.value =~ ""
            result = ParserResult.new valid: true
          else
            result = ParserResult.new valid: false
          end
        else
          result = ParserResult.new valid: false
        end
      else
        # parser_node is nil
        result = ParserResult.new valid: false, partial: true, tail: html_node
      end
      new_scope_chain = scope_chain
    else
      case parser_node.type
      when ParserNode::Types::SOMETHING
        if parser_node.next.nil?
          # {...} has no siblings so it should match whatever it comes
          result = ParserResult.new valid: true
          new_scope_chain = scope_chain
        else
          result, new_scope_chain = execute(parser_node.next, html_node, scope_chain, &block)
        end

        if not result.valid? and not result.partial?
          # a partial result means that parser_node.next matches html_node, but its siblings don't
          # it's not valid, keep trying
          result, new_scope_chain = execute(parser_node, next_node(html_node), scope_chain, &block)
        end
      when ParserNode::Types::BUT
        if parser_node.child.nil?
          # {...but}{/...but} is always valid
            result = ParserResult.new valid: true
            new_scope_chain = scope_chain
        else
          result, new_scope_chain = execute(parser_node.next, html_node, scope_chain, &block)

          if not result.valid?
            temp_result, temp_scope = execute(parser_node.child, html_node, scope_chain, &block)
            if temp_result.valid? or temp_result.partial?
              result = ParserResult.new valid: false
            else
              result, new_scope_chain = execute(parser_node, next_node(html_node), scope_chain, &block)
            end
          end
        end
      when ParserNode::Types::MANY
        iterate = true
        was_valid_once = false
        tail = html_node
        result = nil
        while iterate
          # creates a brand new scope chain per iteration
          per_iteration_scope_chain = scope_chain.clone << Hash.new # scope_chain is cloned so it can be used later
          tail = result.tail unless result.nil?
          result, new_scope_chain = execute(parser_node.child, tail, per_iteration_scope_chain, &block)
          iterate = result.partial?
          was_valid_once = true if !was_valid_once and (result.valid? or result.partial?)
        end
        if was_valid_once
          if not result.valid?
            # give {many} next sibling the chance to evaluate the tail
            result, new_scope_chain = execute(parser_node.next, tail, scope_chain, &block)
          end
        end
      when ParserNode::Types::TAG
        if html_node.element? and parser_node.value == html_node.name
          result, new_scope_chain = execute(parser_node.child, child_node(html_node), scope_chain, &block)
          if result.valid?
            result, temp_scope_chain = execute(parser_node.next, next_node(html_node), new_scope_chain, &block)
            new_scope_chain.merge! temp_scope_chain
          end
        else
          result = ParserResult.new valid: false
          new_scope_chain = scope_chain
        end
      when ParserNode::Types::TEXT
        if html_node.text? and parser_node.value == html_node.text
          result = ParserResult.new valid: true, ans: html_node.text
        else
          result = ParserResult.new valid: false
        end
        new_scope_chain = scope_chain
      when ParserNode::Types::REGEX
        node = html_node
        text = nil
        while not node.nil? and (node.text? or node.name == "br")
          text = "" if text.nil?
          if node.text?
            text << node.text
          else
            text << "\n"
          end
          node = next_node(node)
        end

        if not text.nil? and parser_node.value =~ text
          result = ParserResult.new valid: true, ans: html_node.text
        else
          result = ParserResult.new valid: false
        end
        new_scope_chain = scope_chain
      when ParserNode::Types::SCOPE
        scope_chain << Hash.new
        result, new_scope_chain = execute(parser_node.child, html_node, scope_chain, &block)
      when ParserNode::Types::VARIABLE
        result, new_scope_chain = execute(parser_node.child, html_node, scope_chain, &block)
        if result.valid?
          new_scope_chain[parser_node.value] = result.ans
          block.callback parser_node.value, new_scope_chain if block
        end
      when ParserNode::Types::EITHER
        result, new_scope_chain = execute(parser_node.child, html_node, scope_chain, &block)
        unless result.valid?
          node = parser_node.child
          # look for the next {or}
          while not node.nil? and node.type != ParserNode::Types::OR
            node = node.next
          end
          if node.nil?
            # not found. a partial result means that all the nodes inside the last {or}
            # evaluated true, so the next step is to evaluate the remaining html elements.
            if result.partial?
              result, new_scope_chain = execute(parser_node.next, result.tail, scope_chain, &block)
            end
          else
            temp_node = ParserNode.new ParserNode::Types::EITHER, '', node.next, parser_node.next
            result, new_scope_chain = execute(temp_node, html_node, scope_chain, &block)
          end
        end
        if result.valid?
          result, new_scope_chain = execute(parser_node.next, next_node(html_node), scope_chain, &block)
        end
      when ParserNode::Types::OR
        result = ParserResult.new valid: true
        new_scope_chain = scope_chain
      end
    end

    return result, new_scope_chain
  end
end
