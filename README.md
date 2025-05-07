# openapi-sourcetools

A collection of small tools for OpenAPI format API specifications. This is a work in progress.

The end result is intended to make processing an OpenAPI documents easier for purposes of code generation. As the processing stages done for that purpose can be useful in themselves, the overall process is split to separate Ruby programs.

## Overview

The purpose of openapi-merge is to avoid duplication of parts between documents. Only one in this category but proved useful.

The various openapi-addsomething programs are intended to ensure there is only one copy of each practically identical schema, header, parameter, and response. Besides avoiding duplicated definitions, they also ensure that code generation does not need to check if same type has already been declared, when you process the #/components/schemas section.

The practically identical is from a programming point of view. Summary, description, and examples are ignored by default. That also means that generating documentation for schemas that happen to look the same but are intended to be different loses one of the schemas. The case may occur during gradual move from old types to new ones. Hence generating documentation and code during the same run may be impractical.

If you want to check for duplicate definitions, run the program and compare output with original file. Copy and rename definitions from processed file to the original as appropriate. Names for added component definitions follow the same pattern of TypeNx where Type is Schema, Header, etc. N is a number and x is present only to make find and replace easier as e.g. Schema1x is distinct from Schema10x whereas Schema1 and Schema10 might have issues with replacement in wrong places.

The openapi-processpaths and openapi-frequencies were intended to obtain data about how much various paths are used. Arguably simple to implement even though need for these may be low.

None of these programs verify that the documents fed to them comply with any OpenAPI version. If the document is close enough, processing will succeed.

## Quick Start

To process an API document to obtain a document that has various things moved under components and originals replaced with references, run:

```sh
cat input_document.yaml |
openapi-addschemas |
openapi-addheaders |
openapi-addparameters --add |
openapi-addresponses |
cat > processed_document.yaml
```

To add split paths and to copy security requirement object arrays to operation objects, run:

```sh
cat processed_document.yaml |
openapi-processpaths |
openapi-addsecurityschemes |
cat > generation_source_document.yaml
```

The main effect of the above programs is to add items under components and have other parts refer to those. Since existing items are not touched, there may be duplicates after the processing. For schemas run `openapi-checkschemas` to obtain information about the document.

If the intent is to clean-up the document, omitting `--add` and `openapi-processpaths` is probably desired. Running programs one by one, applying changes and continuing until desired outcome has been reached is probably what you want to do.

## openapi-addschemas

Checks for presence of schma definitions first inside the schemas under "components/schemas", and then elsewhere in the document. Mappings under names "properties", "patternProperties", and "additionalProperties" are checked. For any definition found, adds a definition under "components/schemas" and replaces the original with a reference.

This does not change existing schemas declared at level immediately under "components/schemas" that are practically identical to use references. The properties of objects will be changed to references.

For simple types such as a string with no size or content limitations, output may appear annoying. For processing the document later, I think it is easier to detect that you have another string with different limitations and make a decision to treat it as a different type or provide a function to check the limitations, given a generic string, than to keep track of what you have already encountered when openapi-generate is being run.

## openapi-checkschemas

Checks schemas and reports if they appear to be equivalent. Expects that openapi-addschemas has been run. Does not modify the source document.
Two schemas with same number or properties with same types but different property names can be equivalent. That alone does not mean that one should be dropped as different contexts may have similar types. Mainly intended to be used for checking if there is something to clean up.

## openapi-addheaders

Checks for presence of header definitions under "components/responses" and "paths". For any definition found, adds a definition under "components/headers" and replaces the original with a reference.

This does not change or remove existing header definitions. Those may be practically identical to each other but they will remain. Headers defined inside responses end up referring to one of them if they are practically identical.

You should run openapi-addschemas beforehand to reduce unnecessary variation.

## openapi-addparameters

Checks for presence of parameter definitions under paths. For any definition found, adds a definition under "components/parameters" and replaces the original with a reference.

You should run openapi-addschemas beforehand to reduce unnecessary variation.

If you want all operation objects to have parameters array that includes the parameters listed in path item, use `--add` parameter. While it results in duplication of the parameters array contents, it also avoids chekcing of path item parameters during code generation.

## openapi-addresponses

Checks for presence of response definitions under paths. For any definition found, adds a definition under "components/responses" and replaces the original with a reference.

This does not change existing response definitions even if they are practically identical to each other.

You should run openapi-addschemas beforehand to reduce unnecessary variation.

## openapi-addsecurityschemes

Takes the top-level security array and sets up security arrays in operation objects. The presence of security schemes under components are checked for and missing ones are reported. Intended to simplify later code generation.

## openapi-generate

Loads code that processes the OpenAPI format document and produces output. Increasingly intended to just manage things rather than to do actual work.

Loaded code can add tasks during load time. After everything has been loaded, the tasks are run. Task would usually produce output but can omit it.

The input document can in practice be anything that Ruby YAML module can load. There is a helper task that by default is added first. Since processors loaded later can modify the tasks list, it can be removed and replaced with something else. Hence this might be useful in processing other YAML documents besides API as originally intended. Main benefit in running all together is that the tasks can pass information between each other. Processing same file multiple times would have to rely on code producing exactly same results with regard to variable naming etc. Remains to be seen if this should be elsewhere or if there is something that does the job already.

### Configuration File Convenience Functions

Using the config:name before a gem or Ruby file loading sets the configuration file name prefix that is cleared after the processor has been loaded. The default configration name is only set to the Ruby file base name excluding ".rb". The openapi-generate will not load any configuration files, but configuration file find and read functions are provided for convenience.

The configuration file functions provided in OpenAPISourceTools::ConfigLoader provide a method to find files in the working direectory, read them and return them as an array. The intention is that you can provide multiple files that can be combined together. That allows you to have the general configuration, and other files that override parts of the configuration for example due to the needs of your local environment, or because you need something special this one time.

The file search treats any directory as a key, and files in sub-directories are considered to be nested inside objects with keys equal to the sub-directory names. Any suffix in top-level is used to order the files, so "name" comes before "name1", and that comes before "name2", but they are all considered to be at the root. Consider the following files:

```
cfgname.yaml
cfgname/name.yaml
cfgname/subdir/name.yaml
cfgnamelocal/name.yaml
cfgnamespecial.yaml
```

The "cfgname.yaml" is considered to be at the root and is first. The "cfgnamespecial.yaml" is likewise at the root but ordering of "cfgname", "cfgnamelocal" and "cfgnamespecial" places it as the last file. Files with equal prefixes are sorted fewest keys first, then according to key comparisons, and path comparison as tie-breaker.

Suppose they have the following contents:

```yaml
# cfgname.yaml
rootkey: value

# cfgname/name.yaml
key: value

# cfgname/subdir/name.yaml
subdirkey: value

# cfgnamelocal/name.yaml
localkey: value

# cfgnamespecial.yaml
specialkey: value
```

Reading the files takes into account the names of the sub-directories and names, and adds the file contents underneath those keys. The files above match root-level files that have:

```yaml
# cfgname.yaml
rootkey: value

# cfgname/name.yaml
name:
  key: value

# cfgname/subdir/name.yaml
subdir:
  name:
    subdirkey: value

# cfgnamelocal/name.yaml
name:
  localkey: value

# cfgnamespecial.yaml
specialkey: value
```

The merging of the documents could be done in various ways and is not provided. You could merge all together using deep_merge gem, or you could find the last occurrence of the key in case full replacement of earlier values is what you need. Or whether to combine or override depends on the part of the configuration.

If you deep merge, you have:

```yaml
rootkey: value
name:
  key: value
  localkey: value
subdir:
  name:
    subdirkey: value
specialkey: value
```

If merge at top level, you have:

```yaml
rootkey: value
name:
  localkey: value
subdir:
  name:
    subdirkey: value
specialkey: value
```

In case you need to provide new value to something that is deeply nested but want to avoid creating sub-directories or placing the value under nested keys into the YAML file, possibly because the value is a file you want to use as it is, you can specify a separator character that is treated as a directory separator.

By default the separator is nil since the usage is not common. You probably want to use the same separator for everything under the same directory. Separator applies only to file names, not to keys inside files.

For example you set the separator to "+" by passing "separator:+" to openapi-generate before the configuration files are loaded. In that case the file "cfgname/subdir/name.yaml" can be named as any of the following:

```
cfgname/subdir+name.yaml
cfgname+subdir/name.yaml
cfgname+subdir+name.yaml
```

In case all files exist, the full path is used to order them. Depending on separator character or string, order might not be what you intend. In this case the "+" sign comes before directory separator.

The read_contents function silently ignores any files that YAML parser could not handle. The content of the file is assigned to the key that is determined from the file name. If the file name does not have any separators, it is placed to the root. In that case, if the file does not contain a mapping, it is ignored. This allows you to name related files with the same prefix for clarity.

Use the part matching config prefix to order the file groups. Key depth is used to order files within group.

If your configuration files are not YAML/JSON then you can still use the convenience functions to find the files, but read the files using your own code.

### openapi-generate-checkconfig

This is intended to check what config files are found if the configuration loading convenience functions are used. Allows you to specify config and separator, which are the same values you would use as argument to openapi-generate. Can report if the file is read by the read_contents convenience funcrion, and if value under given key is found in any files and what the value is.

## openapi-merge

Takes multiple documents and adds content without over-writing.

Intended use is to keep common components in one file and add them to multiple API documents to avoid information duplication. Also applies to adding health check path or similar.

Tags are merged based on tag name only. Servers are merged based on url only.

## openapi-modifypaths

Takes a document and allows, adding, deleting, or replacing path prefixes.

You may want to add for example a version string element into the start of the path. Prior to joining multiple documents using openapi-merge, you may want to give each piece an unique prefix. Original API documents could be used with services behind a load balancer that maps paths in combined document and passes the request to the respective service. And so on. You probably could just use "sed" but this might give you fewer opportunities for error with the loss of flexibility.

## openapi-patterntests

Extracts string patterns and length limits from schemas and from patternProperties for use in test case generation in code generators. User can supply strings that match the pattern in pass-array, and strings that do not match the pattern are in fail-array. If there are length limits, fail array contains too short or too long string as applicable. Currently adds empty arrays under pass.

The provided strings should also take into account the length limits so that test cases for too short or too long strings can be added.

Currently does not consider the pattern so test cases must be added manually by the user. Once some patterns are handled automatically, it will still be necessary for the user to check the test strings.

## openapi-processpaths

Splits paths into parts that are fixed or have a parameter. Paths that do not have differences in fixed parts in same place are reported as errors by default. Path is split and stored in path item under key "x-openapi-sourcetools-parts" as an array of hashes with either "fixed" or "parameter" key.

## openapi-frequencies

Takes the output of openapi-processpaths and a log file with one path per line and counts occurrences for each path in the processed API document and saves the count under "freq" key into path object.

## Gem Itself

Very little of the code in the library, if any, usable outside the programs included in the gem. You may want to create classes that provide the methods in TaskInterface, or use ConfigFile methods. Both are available under OpenAPISourceTools module. See tasks.rb and config.rb under lib/openapi/sourcetools directory for details.

In practice, you want to have values for all tasks from a single processor stored either as a specific class instance or hash in Gen.x. There is also Gen.g hash for data that is visible to all tasks. Gen.g usage requires that multiple gems use the keys in similar manner.

Initial value of Gen.x is an empty hash. You can replace it with anything you like as the type and content matter only to your own code. The same Gen.x value is available to the setup code that runs when a gem or Ruby code is required, and to all tasks that the setup added. Other tasks that are run between those two use their own Gen.x value.

You can also ignore Gen.x and Gen.g, and pass same configuration object to all tasks you initialize yourself.

For example your gem might have the following setup task to set itself up.

```ruby
require 'openapi/sourcetools'
require 'deep_merge' # For an example on how to combine all configs.

module GemNamespace
  # Define initialization task:
  class ProcessingInitTask
    include OpenAPISourcetools::TaskInterface

    def generate(context_binding)
      # Output config is not retained between setup_tasks and first task run.
      # You should get full indent etc. config from your configuration files.
      Gen.output.config = OpenAPISourcetools::OutputConfiguration({ 'indent_step' => 2 })
      # Setup all other things you need here...
    end

    def discard
      true # Indicates this task itself does not produce output. Probably clearest that way.
      # Since this returns true, output_name is never called.
    end
  end

  def self.setup_tasks
    # Read configuration here to catch errors early.
    config_name = Gen.config || 'default_config_name'
    cfgs = OpenAPISourceTools::ConfigLoader.find_files(name_prefix: config_name)
    cfgs = OpenAPISourceTools::ConfigLoader.read_contents(cfgs)
    cfg = {}
    cfgs.each { |c| cfg.deep_merge!(c) }
    Gen.x = cfg # Last value in Gen.x is restored when first task is run.
    Gen.add_task(task: ProcessingInitTask.new)
    # Add all other tasks you need here...
  end
end

# Automatically adds setup tasks the first time the gem is required.
GemNamespace.setup_tasks if defined?(Gen)
```

The order of execution is that setup_tasks is run when openapi-generate processes all arguments. The ProcessingInitTask is run once processing proceeds to that task. Hence the setup_tasks method adds tasks after the ProcessingInitTask. Since you can access the tasks array via Gen.tasks, and you have the Gen.task_index indicate the current task (as well as Gen.t), you can add new tasks during processing. That may be useful if you do not actually know what is needed. For expected normal straightforward processing, add tasks during load time.

If the gem needs to be required multiple times, you have to run setup_tasks explicitly. You can either load a ruby file that calls setup_tasks or re-require the gem. You probably need to use different configs so that the previous output is not over-written.

A Ruby file that runs the task setup again could be:

```ruby
# reload-mygem.rb
require 'mygem'
Gen.config = 'mygem-reloaded' # Can avoid config-argument this way.
GemNamespace.setup_tasks
```

If that is all you need to do, considering the gem has been required already, you can use an argument `eval:GemNamespace.setup_tasks` which eliminates the need to add the file. Using a "reload-mygem.rb" file and passing its name to openapi-generate as processor name allows you to do other things like setting the config name to avoid using config-argument.

## Work in Progress

openapi-oftypes is intended for gathering information and making checks so that the code generation for allOf, oneOf, and anyOf becomes simpler.

## License

Copyright © 2021-2025 Ismo Kärkkäinen

Licensed under Universal Permissive License. See LICENSE.txt.
