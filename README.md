# EasyParser
[![Build Status](https://travis-ci.org/gusaaaaa/easyparser.svg?branch=master)](https://travis-ci.org/gusaaaaa/easyparser)

EasyParser is based on one fundamental principle: web scrapers should be understandable by the people that build the web (including designers). EasyParser allows for writing scrapers in the same language web pages are written, accelerating the creation process, maintainance and error correction.

Let's say you want to scrape [a recipe from allrecipes.com](http://allrecipes.com/recipe/grandmas-lemon-meringue-pie/). The following scraper, written in EasyParser language, will do the job:

```html
<html>
  <head>{...}</head>
  <body>
    {...}
    <form>
      {...}
      <div id="wrap">
        {...}
        <div id="content">
          {...}
          <div id="main">
            <div id="center">
              <div id="microformat">
                <div id="hello">
                  <div id="content-wrapper">
                    {...}
                    <div id="zoneRecipe">
                      <div class="ingredients">
                        {...}
                        <div id="zoneIngredients">
                          {...}
                          <div class="ingred-left">
                            <h3>{$ingredients}{/.*/}{/$ingredients}</h3>
                            {...}
                            {many}
                              <ul>
                                {many}
                                  <li>
                                    <label>
                                      {...}
                                      <p>
                                        <span>{$amount}{/.*/}{/$amount}</span>
                                        <span>{$ingredient}{/.*/}{/$ingredient}</span>
                                      </p>
                                    </label>
                                  </li>
                                {/many}
                              </ul>
                            {/many}
                            {...but}<ul>{...}</ul>{/...but}
                          </div>
                          {...}
                        </div>
                        {...}
                      </div>
                      {...}
                    </div>
                  </div>
                </div>
              </div>
            </div>
            {...}
          </div>
          {...}
        </div>
        {...}
      </div>
      {...}
    </form>
    {...}
  </body>
</html>
```

## Disclamer

Remove this disclamer note when EasyParser is not a proof-of-concept anymore.

## How to write a scraper in 5 minutes

```ruby
require_relative 'parser'
ep_source = '
  <html>
    <body>
      <h1>{$heading1}{/.*/}{/$heading1}</h1>
      <h2>{$heading2}{/.*/}{/$heading2}</h2>
      {many}
        <p>{$paragraph}{/.*/}{/$paragraph}</p>
      {/many}
    </body>
  </html>
'
html_source = '
  <html>
    <body>
      <h1>This is awesome!</h1>
      <h2>Do we have something to say?</h2>
      <p>Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nullam eros erat, iaculis nec faucibus non, tempus sit amet mi. Maecenas venenatis luctus mi. Ut ut arcu posuere, aliquet est sed, tempor nunc. Morbi dictum semper augue ut ultrices. Maecenas eget felis vel turpis blandit convallis ut non turpis. Cras consequat id dui quis tempor. Pellentesque sed convallis eros.</p>
      <p>Duis pellentesque purus a urna tempor, in feugiat orci vestibulum. Nullam neque tellus, pharetra nec lectus sed, condimentum dictum lacus. Praesent aliquam tellus eget accumsan placerat. Nam non turpis vitae eros gravida mattis vel eu nibh. Phasellus interdum pulvinar ante, in convallis odio fermentum quis. In hac habitasse platea dictumst. Sed vehicula mollis dui, mollis commodo elit pulvinar nec. Fusce ante nisi, dictum ut adipiscing sodales, scelerisque ac arcu.</p>
      <p>Fusce commodo posuere consectetur. Sed sed ante ut metus suscipit euismod vel sit amet sem. Nunc porttitor sed ipsum sit amet hendrerit. Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Etiam ac vulputate odio, et tempor lectus. Vestibulum pellentesque purus dignissim, molestie ligula at, aliquam dui. Praesent volutpat rhoncus felis sed auctor. Sed ultricies dui et eros mollis laoreet. Proin ultrices vel velit a egestas. Aliquam ullamcorper dictum facilisis. Cras placerat lectus consequat, ullamcorper massa vel, lobortis neque.</p>
    </body>
  </html>
  '
easy_parser = EasyParser.new ep_source do |on|
  on.heading1 do |scope|
    puts "# #{scope['heading1']}"
  end
  on.heading2 do |scope|
    puts "## #{scope['heading2']}"
  end
  on.paragraph do |scope|
    puts scope['paragraph']
  end
end
result, scope = easy_parser.run html_source
```
## Syntax

### Many operator

```
{many}
{/many}
```

### Something operator

```
{...}
```

### Everything but operator

```
{...but}
{/...but}
```

### Tag operator

```
<p>
</p>
```

### Text operator

```
Plain text
```

### Regex operator

```
{/[0-9]+/}
```

### Scope operator

```
{scope}
{/scope}
```

### Variable operator

```
{$this_is_a_variable}
{/$this_is_a_variable}
```

## Roadmap

EasyParser is still a proof-of-concept and we have a myriad of things to fix and improve, including:

- Code refactor, make it modular.
- Add selector operator to go stright to the information we are looking for.
- To be evaluated: incorporate partials [as in Rails](http://guides.rubyonrails.org/layouts_and_rendering.html#using-partials).
- To be evaluated: processing scopes only once the evaluation process has finished.
- Regex capturing.
- Test scopes more thoroughly.
