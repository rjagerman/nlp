# NLP Project - Entity Linking
#
# IO.Annotation
#   Annotation type and functionality


# An annotation defined by an entity and a range
type Annotation
    entity::String
    range::(Int, Int)
    prior::Float16
    Annotation(entity, range) = new(entity, range, 0)
    Annotation(entity, range, prior) = new(entity, range, prior)
end
isequal(a1::Annotation, a2::Annotation) = (a1.entity == a2.entity && a1.range == a2.range)
==(a1::Annotation, a2::Annotation) = isequal(a1, a2)
Base.hash(a::Annotation) = (hash(a.entity) & hash(a.range))
