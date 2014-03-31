require_relative 'parser'
require 'test/unit'
require 'nokogiri'

class TestParser < Test::Unit::TestCase

  def test_parsing_nil_should_yield_invalid_result
    # html - nil
    # |
    # body - nil
    # |
    # div - div - nil
    # |    |
    # nil  nil

    parse_tree =
      (ParserNode.new ParserNode::Types::TAG, 'html',
        (ParserNode.new ParserNode::Types::TAG, 'body',
          (ParserNode.new ParserNode::Types::TAG, 'div', nil,
          (ParserNode.new ParserNode::Types::TAG, 'div', nil, nil)),
          nil
        ),
        nil
      )

    easy_parser = EasyParser.new parse_tree
    result, scope = easy_parser.run('<div></div>')

    assert_equal false, result.valid?
  end

  def test_parsing_tags_without_siblings_yielding_valid_result
    # html - nil
    # |
    # body - nil
    # |
    # div - nil
    # |
    # nil

    parse_tree =
      (ParserNode.new ParserNode::Types::TAG, 'html',
        (ParserNode.new ParserNode::Types::TAG, 'body',
          (ParserNode.new ParserNode::Types::TAG, 'div', nil, nil),
          nil),
        nil)

    easy_parser = EasyParser.new parse_tree
    result, scope = easy_parser.run('<div></div>')

    assert_equal true, result.valid?
  end

  def test_parsing_tags_with_siblings_yielding_valid_result
    # html - nil
    # |
    # body - nil
    # |
    # div ---- p - nil
    # |        |
    # nil      nil

    parse_tree =
      (ParserNode.new ParserNode::Types::TAG, 'html',
        (ParserNode.new ParserNode::Types::TAG, 'body',
          (ParserNode.new ParserNode::Types::TAG, 'div', nil,
          (ParserNode.new ParserNode::Types::TAG, 'p', nil, nil)),
          nil),
        nil)

    easy_parser = EasyParser.new parse_tree
    result, scope = easy_parser.run('<div></div><p></p>')

    assert_equal true, result.valid?
  end

  def test_parsing_tags_yielding_invalid_non_partial_result
    # html - nil
    # |
    # body - nil
    # |
    # div - nil
    # |
    # nil

    parse_tree =
      (ParserNode.new ParserNode::Types::TAG, 'html',
        (ParserNode.new ParserNode::Types::TAG, 'body',
          (ParserNode.new ParserNode::Types::TAG, 'div', nil, nil),
          nil),
        nil)

    easy_parser = EasyParser.new parse_tree
    result, scope = easy_parser.run('<p></p>')

    assert_equal false, result.valid?
    assert_equal false, result.partial?
  end

  def test_parsing_tags_yielding_partial_result
    # html - nil
    # |
    # body - nil
    # |
    # div - nil
    # |
    # nil

    parse_tree =
      (ParserNode.new ParserNode::Types::TAG, 'html',
        (ParserNode.new ParserNode::Types::TAG, 'body',
          (ParserNode.new ParserNode::Types::TAG, 'div', nil, nil),
          nil),
        nil)

    easy_parser = EasyParser.new parse_tree
    result, scope = easy_parser.run('<div><p></p></div>')

    assert_equal false, result.valid?
    assert_equal true, result.partial?
    assert_equal 'p', result.tail.name
  end

  def test_parsing_text_yielding_valid_result
    # html - nil
    # |
    # body - nil
    # |
    # div - nil
    # |
    # "This is cool!" - nil
    # |
    # nil

    parse_tree =
      (ParserNode.new ParserNode::Types::TAG, 'html',
        (ParserNode.new ParserNode::Types::TAG, 'body',
          (ParserNode.new ParserNode::Types::TAG, 'div',
            (ParserNode.new ParserNode::Types::TEXT, 'This is cool!', nil, nil),
            nil),
          nil),
        nil)

    easy_parser = EasyParser.new parse_tree
    result, scope = easy_parser.run('<div>This is cool!</div>')

    assert_equal true, result.valid?
    assert_equal nil, result.ans
  end

  def test_parsing_text_yielding_valid_result_captured_by_variable
    # html - nil
    # |
    # body - nil
    # |
    # p - nil
    # |
    # {$var1} - nil
    # |
    # "This is cool!" - nil
    # |
    # nil

    parse_tree =
      (ParserNode.new ParserNode::Types::TAG, 'html',
        (ParserNode.new ParserNode::Types::TAG, 'body',
          (ParserNode.new ParserNode::Types::TAG, 'p',
            (ParserNode.new ParserNode::Types::VARIABLE, 'var1',
              (ParserNode.new ParserNode::Types::TEXT, 'This is cool!', nil, nil),
              nil),
            nil),
          nil),
        nil)

    easy_parser = EasyParser.new parse_tree
    result, scope = easy_parser.run('<p>This is cool!</p>')

    assert_equal true, result.valid?
    assert_equal 'This is cool!', scope['var1']
  end

  def test_scope_is_shared_among_siblings
    # html - nil
    # |
    # body - nil
    # |
    # p --------------------- p - nil
    # |                       |
    # {$var1} - nil           {$var2} - nil
    # |                       |
    # "This is cool!" - nil   "This is awesome!" - nil
    # |                       |
    # nil                     nil

    parse_tree =
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

    easy_parser = EasyParser.new parse_tree
    result, scope = easy_parser.run('<p>This is cool!</p><p>This is awesome!</p>')

    assert_equal true, result.valid?
    assert_equal 'This is cool!', scope['var1']
    assert_equal 'This is awesome!', scope['var2']
  end

  def test_many_yielding_valid_result
    # html - nil
    # |
    # body - nil
    # |
    # {many} - nil
    # |
    # p - nil
    # |
    # nil

    parse_tree =
      (ParserNode.new ParserNode::Types::TAG, 'html',
        (ParserNode.new ParserNode::Types::TAG, 'body',
          (ParserNode.new ParserNode::Types::MANY, '',
            (ParserNode.new ParserNode::Types::TAG, 'p', nil, nil),
            nil
          ),
          nil
        ),
        nil
      )

    easy_parser = EasyParser.new parse_tree
    result, scope = easy_parser.run('<p></p><p></p><p></p>')

    assert_equal true, result.valid?
  end

  def test_many_yielding_invalid_result
    # html - nil
    # |
    # body - nil
    # |
    # {many} - nil
    # |
    # p - nil
    # |
    # nil

    parse_tree =
      (ParserNode.new ParserNode::Types::TAG, 'html',
        (ParserNode.new ParserNode::Types::TAG, 'body',
          (ParserNode.new ParserNode::Types::MANY, '',
            (ParserNode.new ParserNode::Types::TAG, 'p', nil, nil),
            nil
          ),
          nil
        ),
        nil
      )

    easy_parser = EasyParser.new parse_tree
    result, scope = easy_parser.run('<p></p><p></p><span></span>')

    assert_equal false, result.valid?
  end

  def test_something_test_yielding_valid_result
    # html - nil
    # |
    # body - nil
    # |
    # {...} - span - nil
    # |      |
    # nil    nil

    parse_tree =
      (ParserNode.new ParserNode::Types::TAG, 'html',
        (ParserNode.new ParserNode::Types::TAG, 'body',
          (ParserNode.new ParserNode::Types::SOMETHING, '',
            nil,
            (ParserNode.new ParserNode::Types::TAG, 'span', nil, nil)
          ),
          nil
        ),
        nil
      )

    easy_parser = EasyParser.new parse_tree
    result, scope = easy_parser.run('<p></p><p></p><span></span>')

    assert_equal true, result.valid?
  end

  def test_something_test_yielding_valid_result
    # html - nil
    # |
    # body - nil
    # |
    # {...} - span - nil
    # |      |
    # nil    nil

    parse_tree =
      (ParserNode.new ParserNode::Types::TAG, 'html',
        (ParserNode.new ParserNode::Types::TAG, 'body',
          (ParserNode.new ParserNode::Types::SOMETHING, '',
            nil,
            (ParserNode.new ParserNode::Types::TAG, 'span', nil, nil)
          ),
          nil
        ),
        nil
      )

    easy_parser = EasyParser.new parse_tree
    result, scope = easy_parser.run('<p></p><p></p><span></span><p></p>')

    assert_equal false, result.valid?
  end

  def test_parsing_regex_yielding_invalid_result
    # html - nil
    # |
    # body - nil
    # |
    # div - nil
    # |
    # {/[0-9]+/} - nil
    # |
    # nil

    parse_tree =
      (ParserNode.new ParserNode::Types::TAG, 'html',
        (ParserNode.new ParserNode::Types::TAG, 'body',
          (ParserNode.new ParserNode::Types::TAG, 'div',
            (ParserNode.new ParserNode::Types::REGEX, /[0-9]+/, nil, nil),
            nil),
          nil),
        nil)

    easy_parser = EasyParser.new parse_tree
    result, scope = easy_parser.run('<div>Forty two</div>')

    assert_equal false, result.valid?
  end

  def test_parsing_regex_yielding_valid_result_captured_by_variable
    # html - nil
    # |
    # body - nil
    # |
    # p - nil
    # |
    # {$var1} - nil
    # |
    # {/[0-9]+/} - nil
    # |
    # nil

    parse_tree =
      (ParserNode.new ParserNode::Types::TAG, 'html',
        (ParserNode.new ParserNode::Types::TAG, 'body',
          (ParserNode.new ParserNode::Types::TAG, 'p',
            (ParserNode.new ParserNode::Types::VARIABLE, 'var1',
              (ParserNode.new ParserNode::Types::REGEX, /[0-9]+/, nil, nil),
              nil),
            nil),
          nil),
        nil)

    easy_parser = EasyParser.new parse_tree
    result, scope = easy_parser.run('<p>42</p>')

    assert_equal true, result.valid?
    assert_equal '42', scope['var1']
  end

  def test_block
    # html - nil
    # |
    # body - nil
    # |
    # p - nil
    # |
    # {$var1} - nil
    # |
    # {/[0-9]+/} - nil
    # |
    # nil

    parse_tree =
      (ParserNode.new ParserNode::Types::TAG, 'html',
        (ParserNode.new ParserNode::Types::TAG, 'body',
          (ParserNode.new ParserNode::Types::TAG, 'p',
            (ParserNode.new ParserNode::Types::VARIABLE, 'var1',
              (ParserNode.new ParserNode::Types::REGEX, /[0-9]+/, nil, nil),
              nil),
            nil),
          nil),
        nil)

    value = nil
    easy_parser = EasyParser.new parse_tree do |on|
      on.var1 do |scope|
        value = scope['var1']
      end
    end

    result, scope = easy_parser.run('<p>42</p>')

    assert_equal true, result.valid?
    assert_equal '42', value
  end

end
