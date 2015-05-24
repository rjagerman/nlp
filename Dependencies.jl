# Resolves dependencies of the project
Pkg.update()
for line in eachline(open("REQUIRE"))
    Pkg.add(strip(line))
end
