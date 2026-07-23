///|
/// A value supplied to an RFC 6570 URI Template variable.
///
/// Lists and associative arrays preserve their input order so expansion is
/// deterministic across targets.
pub(all) enum UriValue {
  Scalar(String)
  List(Array[String])
  Assoc(Array[(String, String)])
} derive(Debug, Eq)

///|
enum Operator {
  Simple
  Reserved
  Fragment
  Label
  Path
  PathParameter
  Query
  QueryContinuation
} derive(Debug, Eq)

///|
enum Modifier {
  NoModifier
  Prefix(Int)
  Explode
} derive(Debug, Eq)

///|
struct VariableSpec {
  name : String
  modifier : Modifier
} derive(Debug, Eq)

///|
enum TemplatePart {
  Literal(String)
  Expression(Operator, Array[VariableSpec])
} derive(Debug, Eq)

///|
/// A parsed URI Template that can be expanded repeatedly.
pub struct UriTemplate {
  source : String
  parts : Array[TemplatePart]
  variables : Array[String]
  level : Int
}
