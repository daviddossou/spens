import { describe, expect, it } from "vitest"
import { parseAmount } from "lib/money"

describe("parseAmount", () => {
  it.each([
    ["12,50", 12.5],
    ["12.50", 12.5],
    ["0,5", 0.5],
    ["1 250,50", 1250.5],
    ["1 250 000", 1250000],
    ["1.250,50", 1250.5],
    ["1,250.50", 1250.5],
    ["1,250", 1250],
    ["1.250", 1250],
    ["1.250.000", 1250000],
    ["12,3456", 12.3456],
    ["1'250.5", 1250.5],
    ["-12,5", -12.5],
    ["1500", 1500],
    ["12.", 12],
    [",5", 0.5]
  ])("reads %s as %d", (typed, expected) => {
    expect(parseAmount(typed)).toBe(expected)
  })

  it.each(["", "abc", "12abc", undefined, null])("gives NaN for %s", (typed) => {
    expect(parseAmount(typed)).toBeNaN()
  })
})
