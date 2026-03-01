import Testing
@testable import mut_universal

struct CSVParserTests {
    let parser = CSVParser()

    @Test func parsesSimpleCSV() throws {
        let csv = """
        Serial,Asset Tag,Username
        ABC123,1001,jsmith
        DEF456,1002,jdoe
        """
        let result = try parser.parse(string: csv)
        #expect(result.headers == ["Serial", "Asset Tag", "Username"])
        #expect(result.rowCount == 2)
        #expect(result.rows[0] == ["ABC123", "1001", "jsmith"])
        #expect(result.rows[1] == ["DEF456", "1002", "jdoe"])
    }

    @Test func handlesQuotedFieldsWithCommas() throws {
        let csv = """
        Name,Location
        "Smith, John",Building A
        """
        let result = try parser.parse(string: csv)
        #expect(result.rows[0][0] == "Smith, John")
        #expect(result.rows[0][1] == "Building A")
    }

    @Test func handlesQuotedFieldsWithNewlines() throws {
        let csv = "Name,Notes\n\"John\",\"Line 1\nLine 2\"\n"
        let result = try parser.parse(string: csv)
        #expect(result.rowCount == 1)
        #expect(result.rows[0][1] == "Line 1\nLine 2")
    }

    @Test func handlesEscapedQuotes() throws {
        let csv = "Name,Quote\nJohn,\"He said \"\"hello\"\"\""
        let result = try parser.parse(string: csv)
        #expect(result.rows[0][1] == "He said \"hello\"")
    }

    @Test func throwsOnEmptyCSV() throws {
        #expect(throws: MUTError.self) {
            try parser.parse(string: "")
        }

        #expect(throws: MUTError.self) {
            try parser.parse(string: "   \n  \n  ")
        }
    }

    @Test func throwsOnInconsistentColumnCount() throws {
        let csv = "A,B,C\n1,2,3\n4,5"
        #expect(throws: MUTError.self) {
            try parser.parse(string: csv)
        }
    }

    @Test func handlesWindowsLineEndings() throws {
        let csv = "Serial,Tag\r\nABC,001\r\nDEF,002\r\n"
        let result = try parser.parse(string: csv)
        #expect(result.headers == ["Serial", "Tag"])
        #expect(result.rowCount == 2)
        #expect(result.rows[0] == ["ABC", "001"])
        #expect(result.rows[1] == ["DEF", "002"])
    }

    @Test func stripsWhitespace() throws {
        let csv = " Serial , Tag \n  ABC  , 001  "
        let result = try parser.parse(string: csv)
        #expect(result.headers == ["Serial", "Tag"])
        #expect(result.rows[0] == ["ABC", "001"])
    }

    @Test func skipsEmptyRows() throws {
        let csv = "Serial,Tag\nABC,001\n\nDEF,002\n"
        let result = try parser.parse(string: csv)
        #expect(result.rowCount == 2)
        #expect(result.rows[0] == ["ABC", "001"])
        #expect(result.rows[1] == ["DEF", "002"])
    }
}
