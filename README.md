# RedNails

### Description

RedNails is a data scraping library that uses templates to determine what data
to extract from actual data feeds.

RedNails uses the template to create a regular expression that catches the
user marker variables.  When a string of data is passed to RedNails it will
use the regular expression to extract the matches and return them to the user.

If the scraped data is regular enough then RedNails is a simple way to extract
data as all one needs to do is copy a live data feed and mark the points to
extract and make this the template.

### License: BSD

### Usage

1. Create a template.
2. Load and initialize an instance of a RedNails object with the template.
3. Pass this instance your data feed from which you wish to extract information.
4. Use the results.

### Template Format

A RedNails template is simply a text file that has the points to scrape marked
with what looks like a ruby string substitution.  You give each substitution a
unique variable name that can be referenced when using the parse_hash method.

An example template is:

```
"Hello my name is #{name}.  How are you?"

If the data string to scrape is:

"Hello my name is Mr.Bill.  How are you?"
```

Then the following code fragement will produce "Mr.Bill":

```ruby
 require 'rednails'
 rednails = RedNails.new("template.txt")
 results = rednails.parse_hash("livedata.txt")
 puts results["name"] # => Mr.Bill
```

### Repetitions

If have data that you would like to extract which repeats itself then there is
an additional template marker you can use.
For the first example replace the data with #{Rep:} after the colon inside of
the Rep marker you will then place the structured data that repeats, except
that for each unique piece of data that you would like to extract replace it
with a unique variable name that starts and ends with @.

For example if you have an arbitrary list of images that you would like to
extract you can make a template like this:

```html
<html>
  <body>
    A bunch of photos:
    #{Rep:<img src="@url@" alt="@txt@"/>}
  </body>
</html>
```

For more details please see the test cases.

### Installation

* Gem: gem install RedNails

* Manual: ruby setup.rb all


### Author and Contributions

* Zev Blut
* With some changes and help by Min Lin Hsieh, Daniel DeLorme and Pierre Baumard.
