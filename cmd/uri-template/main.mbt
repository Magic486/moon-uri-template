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
enum CliCommand {
  Validate(String)
  Variables(String)
  Inspect(String)
  Expand(String, String)
} derive(Debug, Eq)

///|
suberror CliError {
  InvalidInvocation(message~ : String)
} derive(Debug)

///|
impl Show for CliError with fn output(self, logger) {
  match self {
    InvalidInvocation(message~) => logger.write_string(message)
  }
}

///|
fn parse_command(args : ArrayView[String]) -> CliCommand raise CliError {
  if args.length() < 2 {
    raise InvalidInvocation(message="missing command")
  }
  let command = args[1]
  match command {
    "validate" | "variables" | "inspect" => {
      if args.length() != 3 {
        raise InvalidInvocation(
          message="'\{command}' expects exactly one TEMPLATE argument",
        )
      }
      let source = args[2]
      match command {
        "validate" => Validate(source)
        "variables" => Variables(source)
        _ => Inspect(source)
      }
    }
    "expand" => {
      if args.length() != 5 || args[3] != "--variables" {
        raise InvalidInvocation(
          message="'expand' expects TEMPLATE --variables FILE.json",
        )
      }
      Expand(args[2], args[4])
    }
    _ => raise InvalidInvocation(message="unknown command: \{command}")
  }
}

///|
fn render_template_summary(source : String, inspect~ : Bool) -> String raise {
  let template = @uri.UriTemplate::parse(source)
  if inspect {
    let variables = template.variables()
    let suffix = if variables.length() == 0 {
      ""
    } else {
      "\n" + variables.join("\n")
    }
    "source: \{template.source()}\n" +
    "level: \{template.level()}\n" +
    "variables:\{suffix}"
  } else {
    "valid RFC 6570 Level \{template.level()} template; " +
    "\{template.variables().length()} variable(s)"
  }
}

///|
fn expand_from_json(source : String, text : String) -> String raise {
  let template = @uri.UriTemplate::parse(source)
  let json = @json.parse(text)
  let variables = @uri.variables_from_json(json)
  template.expand(variables)
}

///|
fn execute_command(command : CliCommand) -> String raise {
  match command {
    Validate(source) => render_template_summary(source, inspect=false)
    Variables(source) => {
      let template = @uri.UriTemplate::parse(source)
      template.variables().join("\n")
    }
    Inspect(source) => render_template_summary(source, inspect=true)
    Expand(source, path) => {
      let text = @fs.read_file_to_string(path)
      expand_from_json(source, text)
    }
  }
}

///|
fn run(args : Array[String]) -> Unit raise {
  let output = execute_command(parse_command(args))
  if output != "" {
    println(output)
  }
}

///|
fn main {
  run(@sys.get_cli_args()) catch {
    InvalidInvocation(message~) => {
      println("error: \{message}")
      println(usage())
      @sys.exit(2)
    }
    error => {
      println("error: \{error}")
      @sys.exit(1)
    }
  }
}
