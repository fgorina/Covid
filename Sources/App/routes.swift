import Fluent
import Vapor
import Leaf

func routes(_ app: Application) throws {
    app.get { req in
        return req.view.render("welcome.leaf")
    }

    app.get("hello") { req -> String in
        return "Hello, world!"
    }

    try app.register(collection: CovidController())
}
