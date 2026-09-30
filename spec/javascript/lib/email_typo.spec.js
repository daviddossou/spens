import { describe, expect, it } from "vitest"
import { suggestEmail } from "lib/email_typo"

describe("suggestEmail", () => {
  it.each([
    ["ama@gmial.com", "ama@gmail.com"],
    ["ama@gmai.com", "ama@gmail.com"],
    ["ama@gmail.co", "ama@gmail.com"],
    ["Ama@Hotmial.fr", "ama@hotmail.fr"],
    ["ama@yaho.fr", "ama@yahoo.fr"],
    ["ama@outlok.com", "ama@outlook.com"],
    ["ama@oragne.fr", "ama@orange.fr"]
  ])("fixes %s to %s", (typed, expected) => {
    expect(suggestEmail(typed)).toBe(expected)
  })

  it.each([
    "ama@gmail.com", "ama@yahoo.fr", "ama@anka.africa", "ama@moov-africa.bj", "ama@live.fr",
    "not-an-email", "ama@", "@gmail.com", "", null
  ])("leaves %s alone", (typed) => {
    expect(suggestEmail(typed)).toBeNull()
  })
})
