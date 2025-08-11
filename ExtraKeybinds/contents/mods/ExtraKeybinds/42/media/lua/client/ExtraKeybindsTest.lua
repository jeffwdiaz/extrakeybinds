-- Extra Keybinds Mod - Test Functions
-- Test functions for validating literature categorization

require "ExtraKeybindsLiteratureCategories"

ExtraKeybindsTest = {}

-- Test function to verify leisure magazine detection
function ExtraKeybindsTest.testLeisureMagazineDetection()
    print("=== Testing Leisure Magazine Detection ===")
    
    -- Test items that should be detected as leisure magazines
    local testItems = {
        {id = "Magazine", expected = true, desc = "Generic magazine"},
        {id = "HottieZ_New", expected = true, desc = "HottieZ magazine"},
        {id = "TVMagazine", expected = true, desc = "TV Magazine"},
        {id = "Magazine_Popular", expected = true, desc = "Popular Magazine"},
        {id = "MagazineCrossword", expected = true, desc = "Crossword Magazine"},
        {id = "TailoringMag9", expected = false, desc = "Recipe magazine (should NOT match)"},
        {id = "BookFarming1", expected = false, desc = "Skill book (should NOT match)"},
        {id = "Paperback", expected = false, desc = "Paperback book (should NOT match)"}
    }
    
    for _, test in ipairs(testItems) do
        -- Create a mock item for testing
        local mockItem = {
            getFullType = function() return "Base." .. test.id end,
            getType = function() return test.id end
        }
        
        local result = ExtraKeybindsCategories.isLeisureMagazine(mockItem)
        local status = (result == test.expected) and "PASS" or "FAIL"
        
        print(string.format("%s: %s - %s (got %s, expected %s)", 
            status, test.id, test.desc, tostring(result), tostring(test.expected)))
    end
    
    print("=== Leisure Magazine Test Complete ===")
end

-- Test function to verify recipe magazine detection
function ExtraKeybindsTest.testRecipeMagazineDetection()
    print("=== Testing Recipe Magazine Detection ===")
    
    local testItems = {
        {id = "TailoringMag9", expected = true, desc = "Tailoring magazine"},
        {id = "SmithingMag8", expected = true, desc = "Smithing magazine"},
        {id = "CookingMag1", expected = true, desc = "Cooking magazine"},
        {id = "Magazine", expected = false, desc = "Generic magazine (should NOT match)"},
        {id = "TVMagazine", expected = false, desc = "TV magazine (should NOT match)"}
    }
    
    for _, test in ipairs(testItems) do
        local mockItem = {
            getFullType = function() return "Base." .. test.id end,
            getType = function() return test.id end
        }
        
        local result = ExtraKeybindsCategories.isRecipeMagazine(mockItem)
        local status = (result == test.expected) and "PASS" or "FAIL"
        
        print(string.format("%s: %s - %s (got %s, expected %s)", 
            status, test.id, test.desc, tostring(result), tostring(test.expected)))
    end
    
    print("=== Recipe Magazine Test Complete ===")
end

-- Console command to run tests
local function runCategoryTests()
    ExtraKeybindsTest.testLeisureMagazineDetection()
    print("")
    ExtraKeybindsTest.testRecipeMagazineDetection()
end

-- Register console command for testing (if debug mode is available)
if getDebug then
    Events.OnGameStart.Add(function()
        print("ExtraKeybinds: Test functions loaded. Use 'runCategoryTests()' in console to test categorization.")
    end)
end
