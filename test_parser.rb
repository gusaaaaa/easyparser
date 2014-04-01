require_relative 'parser'
require 'test/unit'

class TestParser < Test::Unit::TestCase

  def test_parsing_nil_should_yield_invalid_result
    source = '
    <html>
      <body>
        <div></div>
        <div></div>
      </body>
    </html>
    '

    easy_parser = EasyParser.new source
    result, scope = easy_parser.run('<div></div>')

    assert_equal false, result.valid?
  end

  def test_parsing_tags_without_siblings_yielding_valid_result
    source = '
    <html>
      <body>
        <div></div>
      </body>
    </html>
    '

    easy_parser = EasyParser.new source
    result, scope = easy_parser.run('<div></div>')

    assert_equal true, result.valid?
  end

  def test_parsing_tags_with_siblings_yielding_valid_result
    source = '
    <html>
      <body>
        <div></div>
        <p></p>
      </body>
    </html>
    '

    easy_parser = EasyParser.new source
    result, scope = easy_parser.run('<div></div><p></p>')

    assert_equal true, result.valid?
  end

  def test_parsing_tags_yielding_invalid_non_partial_result
    source = '
    <html>
      <body>
        <div></div>
      </body>
    </html>
    '

    easy_parser = EasyParser.new source
    result, scope = easy_parser.run('<p></p>')

    assert_equal false, result.valid?
    assert_equal false, result.partial?
  end

  def test_parsing_tags_yielding_partial_result
    source = '
    <html>
      <body>
        <div></div>
      </body>
    </html>
    '

    easy_parser = EasyParser.new source
    result, scope = easy_parser.run('<div><p></p></div>')

    assert_equal false, result.valid?
    assert_equal true, result.partial?
    assert_equal 'p', result.tail.name
  end

  def test_parsing_text_yielding_valid_result
    source = '
    <html>
      <body>
        <div>This is cool!</div>
      </body>
    </html>
    '

    easy_parser = EasyParser.new source
    result, scope = easy_parser.run('<div>This is cool!</div>')

    assert_equal true, result.valid?
    assert_equal nil, result.ans
  end

  def test_parsing_text_yielding_valid_result_captured_by_variable
    source = '
    <html>
      <body>
        <p>{$var1}This is cool!{/$var1}</p>
      </body>
    </html>
    '

    easy_parser = EasyParser.new source
    result, scope = easy_parser.run('<p>This is cool!</p>')

    assert_equal true, result.valid?
    assert_equal 'This is cool!', scope['var1']
  end

  def test_scope_is_shared_among_siblings
    source = '
    <html>
      <body>
        <p>
          <ep-variable name="var1">This is cool!</ep-variable>
        </p>
        <p>
          <ep-variable name="var2">This is awesome!</ep-variable>
        </p>
      </body>
    </html>
    '

    easy_parser = EasyParser.new source
    result, scope = easy_parser.run('<p>This is cool!</p><p>This is awesome!</p>')

    assert_equal true, result.valid?
    assert_equal 'This is cool!', scope['var1']
    assert_equal 'This is awesome!', scope['var2']
  end

  def test_many_yielding_valid_result
    source = '
    <html>
      <body>
        {many}
          <p></p>
        {/many}
      </body>
    </html>
    '

    easy_parser = EasyParser.new source
    result, scope = easy_parser.run('<p></p><p></p><p></p>')

    assert_equal true, result.valid?
  end

  def test_many_yielding_invalid_result
    source = '
    <html>
      <body>
        {many}
          <p></p>
        {/many}
      </body>
    </html>
    '

    easy_parser = EasyParser.new source
    result, scope = easy_parser.run('<p></p><p></p><span></span>')

    assert_equal false, result.valid?
  end

  def test_something_test_yielding_valid_result
    source = '
    <html>
      <body>
        {...}
        <span></span>
      </body>
    </html>
    '

    easy_parser = EasyParser.new source
    result, scope = easy_parser.run('<p></p><p></p><span></span>')

    assert_equal true, result.valid?
  end

  def test_something_test_yielding_invalid_result
    source = '
    <html>
      <body>
        {...}
        <span></span>
      </body>
    </html>
    '

    easy_parser = EasyParser.new source
    result, scope = easy_parser.run('<p></p><p></p><span></span><p></p>')

    assert_equal false, result.valid?
  end

  def test_parsing_regex_yielding_invalid_result
    source = '
    <html>
      <body>
        <div>
          {$var1}{/[0-9]+/}{/$var1}
        </div>
      </body>
    </html>
    '

    easy_parser = EasyParser.new source
    result, scope = easy_parser.run('<div>Forty two</div>')

    assert_equal false, result.valid?
  end

  def test_parsing_regex_yielding_valid_result_captured_by_variable
    source = '
    <html>
      <body>
        <p>
          {$var1}{/[0-9]+/}{/$var1}
        </p>
      </body>
    </html>
    '

    easy_parser = EasyParser.new source
    result, scope = easy_parser.run('<p>42</p>')

    assert_equal true, result.valid?
    assert_equal '42', scope['var1']
  end

  def test_block
    source = '
    <html>
      <body>
        <p>
          {$var1}{/[0-9]+/}{/$var1}
        </p>
      </body>
    </html>
    '

    value = nil
    easy_parser = EasyParser.new source do |on|
      on.var1 do |scope|
        value = scope['var1']
      end
    end

    result, scope = easy_parser.run('<p>42</p>')

    assert_equal true, result.valid?
    assert_equal '42', value
  end

  def test_snippets_after_html_should_be_valid
    source = '
    <html>
      {...}
      <body>
        <p></p>
      </body>
    </html>
    '

    easy_parser = EasyParser.new source
    result, scope = easy_parser.run('
      <html>
        <head><title>Hola!</title></head>
        <body>
          <p></p>
        </body>
      </html>
    ')

    assert_equal true, result.valid?
  end

end
