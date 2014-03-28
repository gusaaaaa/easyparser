require_relative 'parser'
require 'test/unit'
require 'nokogiri'

class TestParser < Test::Unit::TestCase

  def test_parsing_tags_without_siblings_yielding_valid_result
    parser_node =
      (ParserNode.new ParserNode::Types::TAG, 'html',
        (ParserNode.new ParserNode::Types::TAG, 'body',
          (ParserNode.new ParserNode::Types::TAG, 'div', nil, nil),
          nil),
        nil)
    html_doc = Nokogiri::HTML '<div></div>'
    result, scope = parse(parser_node, html_doc.root, ScopeChain.new)
    assert_equal true, result.valid?
  end

  def test_parsing_tags_with_siblings_yielding_valid_result
    parser_node =
      (ParserNode.new ParserNode::Types::TAG, 'html',
        (ParserNode.new ParserNode::Types::TAG, 'body',
          (ParserNode.new ParserNode::Types::TAG, 'div', nil,
          (ParserNode.new ParserNode::Types::TAG, 'p', nil, nil)),
          nil),
        nil)
    html_doc = Nokogiri::HTML '<div></div><p></p>'
    result, scope = parse(parser_node, html_doc.root, ScopeChain.new)
    assert_equal true, result.valid?
  end

  def test_parsing_tags_yielding_invalid_non_partial_result
    parser_node =
      (ParserNode.new ParserNode::Types::TAG, 'html',
        (ParserNode.new ParserNode::Types::TAG, 'body',
          (ParserNode.new ParserNode::Types::TAG, 'div', nil, nil),
          nil),
        nil)
    html_doc = Nokogiri::HTML '<p></p>'
    result, scope = parse(parser_node, html_doc.root, ScopeChain.new)
    assert_equal false, result.valid?
    assert_equal false, result.partial?
  end

  def test_parsing_tags_yielding_partial_result
    parser_node =
      (ParserNode.new ParserNode::Types::TAG, 'html',
        (ParserNode.new ParserNode::Types::TAG, 'body',
          (ParserNode.new ParserNode::Types::TAG, 'div', nil, nil),
          nil),
        nil)
    html_doc = Nokogiri::HTML '<div><p></p></div>'
    result, scope = parse(parser_node, html_doc.root, ScopeChain.new)
    assert_equal false, result.valid?
    assert_equal true, result.partial?
    assert_equal 'p', result.tail.name
  end

  def test_parsing_text_yielding_valid_result
    parser_node =
      (ParserNode.new ParserNode::Types::TAG, 'html',
        (ParserNode.new ParserNode::Types::TAG, 'body',
          (ParserNode.new ParserNode::Types::TAG, 'div',
            (ParserNode.new ParserNode::Types::TEXT, 'This is cool!', nil, nil),
            nil),
          nil),
        nil)
    html_doc = Nokogiri::HTML '<div>This is cool!</div>'
    result, scope = parse(parser_node, html_doc.root, ScopeChain.new)
    assert_equal true, result.valid?
    assert_equal nil, result.ans
  end

  def test_parsing_text_yielding_valid_result_captured_by_variable
    parser_node =
      (ParserNode.new ParserNode::Types::TAG, 'html',
        (ParserNode.new ParserNode::Types::TAG, 'body',
          (ParserNode.new ParserNode::Types::TAG, 'p',
            (ParserNode.new ParserNode::Types::VARIABLE, 'var1',
              (ParserNode.new ParserNode::Types::TEXT, 'This is cool!', nil, nil),
              nil),
            nil),
          nil),
        nil)
    html_doc = Nokogiri::HTML '<p>This is cool!</p>'
    result, scope = parse(parser_node, html_doc.root, ScopeChain.new)
    assert_equal true, result.valid?
    assert_equal 'This is cool!', scope['var1']
  end

  def test_scope_is_shared_among_siblings
    parser_node =
      (ParserNode.new ParserNode::Types::TAG, 'html',
        (ParserNode.new ParserNode::Types::TAG, 'body',
          (ParserNode.new ParserNode::Types::TAG, 'p',
            (ParserNode.new ParserNode::Types::VARIABLE, 'var1',
              (ParserNode.new ParserNode::Types::TEXT, 'This is cool!', nil, nil),
              nil),
          (ParserNode.new ParserNode::Types::TAG, 'p',
            (ParserNode.new ParserNode::Types::VARIABLE, 'var2',
              (ParserNode.new ParserNode::Types::TEXT, 'This is awesome!', nil, nil),
              nil),
            nil) 
          ),
        nil),
      nil)
    html_doc = Nokogiri::HTML '<p>This is cool!</p><p>This is awesome!</p>'
    result, scope = parse(parser_node, html_doc.root, ScopeChain.new)
    assert_equal true, result.valid?
    assert_equal 'This is cool!', scope['var1']
    assert_equal 'This is awesome!', scope['var2']
  end
end
