export function typedLowercased<Value extends string>(
  value: Value
): Lowercase<Value> {
  return value.toLowerCase() as Lowercase<Value>;
}
