import Foundation

enum SortOption: String, CaseIterable, Identifiable {
    case relevance = "relevance"
    case dateDesc = "date_desc"
    case gradeAsc = "grade_asc"
    case nameAsc = "name_asc"
    case nameDesc = "name_desc"
    var id: Self { self }

    var displayName: String {
        switch self {
            case .relevance: "Relevance"
            case .dateDesc: "Date (Newest)"
            case .gradeAsc: "Grade (A-C)"
            case .nameAsc: "Name (A-Z)"
            case .nameDesc: "Name (Z-A)"
        }
    }
}

enum BoroOption: String, CaseIterable, Identifiable {
    case any = "Any"
    case manhattan = "Manhattan"
    case brooklyn = "Brooklyn"
    case queens = "Queens"
    case bronx = "Bronx"
    case statenIsland = "Staten Island"
    var id: Self { self }
}

enum GradeOption: String, CaseIterable, Identifiable {
    case any = "Any"
    case a = "A"
    case b = "B"
    case c = "C"
    case pending = "P"
    var id: Self { self }
    
    var displayName: String {
        switch self {
        case .any: "Any"
        case .a: "Grade A"
        case .b: "Grade B"
        case .c: "Grade C"
        case .pending: "Grade Pending"
        }
    }
}

enum CuisineOption: String, CaseIterable, Identifiable {
    case any = "Any"
    case african = "African"
    case american = "American"
    case armenian = "Armenian"
    case asianAsianFusion = "Asian/Asian Fusion"
    case australian = "Australian"
    case bagelsPretzels = "Bagels/Pretzels"
    case bakeryProductsDesserts = "Bakery Products/Desserts"
    case bangladeshi = "Bangladeshi"
    case barbecue = "Barbecue"
    case basque = "Basque"
    case bottledBeverages = "Bottled Beverages"
    case brazilian = "Brazilian"
    case cajun = "Cajun"
    case californian = "Californian"
    case caribbean = "Caribbean"
    case chicken = "Chicken"
    case chilean = "Chilean"
    case chimichurri = "Chimichurri"
    case chinese = "Chinese"
    case chineseCuban = "Chinese/Cuban"
    case chineseJapanese = "Chinese/Japanese"
    case coffeeTea = "Coffee/Tea"
    case continental = "Continental"
    case creole = "Creole"
    case creoleCajun = "Creole/Cajun"
    case czech = "Czech"
    case donuts = "Donuts"
    case easternEuropean = "Eastern European"
    case egyptian = "Egyptian"
    case english = "English"
    case ethiopian = "Ethiopian"
    case filipino = "Filipino"
    case french = "French"
    case frozenDesserts = "Frozen Desserts"
    case fruitsVegetables = "Fruits/Vegetables"
    case fusion = "Fusion"
    case german = "German"
    case greek = "Greek"
    case hamburgers = "Hamburgers"
    case hauteCuisine = "Haute Cuisine"
    case hawaiian = "Hawaiian"
    case hotdogs = "Hotdogs"
    case hotdogsPretzels = "Hotdogs/Pretzels"
    case indian = "Indian"
    case indonesian = "Indonesian"
    case iranian = "Iranian"
    case irish = "Irish"
    case italian = "Italian"
    case japanese = "Japanese"
    case jewishKosher = "Jewish/Kosher"
    case juiceSmoothiesFruitSalads = "Juice, Smoothies, Fruit Salads"
    case korean = "Korean"
    case latinAmerican = "Latin American"
    case lebanese = "Lebanese"
    case mediterranean = "Mediterranean"
    case mexican = "Mexican"
    case middleEastern = "Middle Eastern"
    case moroccan = "Moroccan"
    case newAmerican = "New American"
    case newFrench = "New French"
    case notListedNotApplicable = "Not Listed/Not Applicable"
    case nutsConfectionary = "Nuts/Confectionary"
    case other = "Other"
    case pakistani = "Pakistani"
    case pancakesWaffles = "Pancakes/Waffles"
    case peruvian = "Peruvian"
    case pizza = "Pizza"
    case polish = "Polish"
    case portuguese = "Portuguese"
    case russian = "Russian"
    case salads = "Salads"
    case sandwiches = "Sandwiches"
    case sandwichesSaladsMixedBuffet = "Sandwiches/Salads/Mixed Buffet"
    case scandinavian = "Scandinavian"
    case seafood = "Seafood"
    case soulFood = "Soul Food"
    case soups = "Soups"
    case soupsSaladsSandwiches = "Soups/Salads/Sandwiches"
    case southeastAsian = "Southeast Asian"
    case southwestern = "Southwestern"
    case spanish = "Spanish"
    case steakhouse = "Steakhouse"
    case tapas = "Tapas"
    case texMex = "Tex-Mex"
    case thai = "Thai"
    case turkish = "Turkish"
    case vegan = "Vegan"
    case vegetarian = "Vegetarian"
    
    var id: Self { self }
}
