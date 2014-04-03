require 'easyparser'

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
  <h1>This is awesome!</h1>
  <h2>Do we have something to say?</h2>
  <p>Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nullam eros erat, iaculis nec faucibus non, tempus sit amet mi. Maecenas venenatis luctus mi. Ut ut arcu posuere, aliquet est sed, tempor nunc. Morbi dictum semper augue ut ultrices. Maecenas eget felis vel turpis blandit convallis ut non turpis. Cras consequat id dui quis tempor. Pellentesque sed convallis eros.</p>
  <p>Duis pellentesque purus a urna tempor, in feugiat orci vestibulum. Nullam neque tellus, pharetra nec lectus sed, condimentum dictum lacus. Praesent aliquam tellus eget accumsan placerat. Nam non turpis vitae eros gravida mattis vel eu nibh. Phasellus interdum pulvinar ante, in convallis odio fermentum quis. In hac habitasse platea dictumst. Sed vehicula mollis dui, mollis commodo elit pulvinar nec. Fusce ante nisi, dictum ut adipiscing sodales, scelerisque ac arcu.</p>
  <p>Fusce commodo posuere consectetur. Sed sed ante ut metus suscipit euismod vel sit amet sem. Nunc porttitor sed ipsum sit amet hendrerit. Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Etiam ac vulputate odio, et tempor lectus. Vestibulum pellentesque purus dignissim, molestie ligula at, aliquam dui. Praesent volutpat rhoncus felis sed auctor. Sed ultricies dui et eros mollis laoreet. Proin ultrices vel velit a egestas. Aliquam ullamcorper dictum facilisis. Cras placerat lectus consequat, ullamcorper massa vel, lobortis neque.</p>
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
p result
