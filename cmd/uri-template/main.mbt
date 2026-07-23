///|
fn usage() -> String {
  (
    #|moon-uri-template — RFC 6570 Level 4 URI Template tools
    #|
    #|Usage:
    #|  moon-uri-template validate TEMPLATE
    #|  moon-uri-template variables TEMPLATE
    #|  moon-uri-template inspect TEMPLATE
    #|  moon-uri-template expand TEMPLATE --variables FILE.json
    #|
  )
}

///|
fn print_variables(variables : Array[String]) -> Unit {
  for variable in variables {
    println(variable)
  }
}

///|
fn run(args : Array[String]) -> Unit raise {
  if args.length() < 3 {
    println(usage())
    @sys.exit(2)
  }
  let command = args[1]
  let source = args[2]
  let template = @uri.UriTemplate::parse(source)
  match command {
    "validate" =>
      println(
        "valid RFC 6570 Level \{template.level()} template; " +
        "\{template.variables().length()} variable(s)",
      )
    "variables" => print_variables(template.variables())
    "inspect" => {
      println("source: \{template.source()}")
      println("level: \{template.level()}")
      println("variables:")
      print_variables(template.variables())
    }
    "expand" => {
      if args.length() != 5 || args[3] != "--variables" {
        println(usage())
        @sys.exit(2)
      }
      let text = @fs.read_file_to_string(args[4])
      let json = @json.parse(text)
      let variables = @uri.variables_from_json(json)
      println(template.expand(variables))
    }
    _ => {
      println("unknown command: \{command}")
      println(usage())
      @sys.exit(2)
    }
  }
}

///|
fn main {
  run(@sys.get_cli_args()) catch {
    error => {
      println("error: \{error}")
      @sys.exit(1)
    }
  }
}
