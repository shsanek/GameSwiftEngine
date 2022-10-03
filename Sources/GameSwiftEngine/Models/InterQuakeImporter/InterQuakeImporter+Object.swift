import simd

extension InterQuakeImporter.Object {
    public func getIndexs() -> [UInt32] {
        poligons.flatMap { [UInt32($0.a), UInt32($0.b), UInt32($0.c)] }
    }

    public func getVertexs() -> [VertexInput] {
        vertex.map {
            getVertex(from: $0)
        }
    }

    public func getBoneTransform(
        with index: Int? = nil
    ) -> [BoneTransform] {
        let raws: [InterQuakeImporter.Bone]
        if let index = index, frame.count > index {
            raws = frame[index].bones
        } else {
            raws = bone
        }
        weak var weakStorage: LazyReques<Int, matrix_float4x4>? = nil
        let storage: LazyReques<Int, matrix_float4x4> = .init { index in
            getTransform(for: raws[index], storage: weakStorage)
        }
        weakStorage = storage
        return raws.enumerated().map { .init(transform: storage.fetch(with: $0.offset)) }
    }

    func getVertex(from vertex: InterQuakeImporter.Vertex) -> VertexInput {
        var input = VertexInput(position: vertex.position, uv: vertex.uv ?? .zero)
        var binds: [InputBoneBind] = vertex.binding.map { .init(index: Int32($0.index), width: $0.power) }
        binds = Array(binds.sorted(by: { $0.width > $1.width }).prefix(4))
        while binds.count < 4 { binds.append(.empty) }
        let sum = binds.reduce(GEFloat(0), { $0 + $1.width })
        if sum > 0 {
            binds = binds.map { .init(index: $0.index + 1, width: $0.width / sum) }
        }
        input.boneA = binds[0]
        input.boneB = binds[1]
        input.boneC = binds[2]
        input.boneD = binds[3]
        return input
    }

    func getTransform(
        for bone: InterQuakeImporter.Bone,
        storage: LazyReques<Int, matrix_float4x4>?
    ) -> matrix_float4x4 {
        var transform = getLocalTransform(for: bone)

        if bone.parent >= 0 {
            if let matrix = storage?.fetch(with: bone.parent) {
                transform = matrix * transform
            }
        }

        return transform
    }

    func getLocalTransform(for bone: InterQuakeImporter.Bone) -> matrix_float4x4 {
        let q = simd_quatf(vector: normalize(bone.transform.quaternion))
        let one: GEFloat = 1
        let zero: GEFloat = 0

        var rotate = rotationMatrix4x4(radians: q.angle, axis: q.axis)
        if rotate[0][0].isNaN {
            rotate = .init(1)
        }
        let scale = matrix_float4x4(
            vector_float4(bone.transform.scale.x, zero, zero, zero),
            vector_float4(zero, bone.transform.scale.y, zero, zero),
            vector_float4(zero, zero, bone.transform.scale.z, zero),
            vector_float4(zero, zero, zero, one)
        )
        let translate = translationMatrix4x4(
            bone.transform.translate.x,
            bone.transform.translate.y,
            bone.transform.translate.z
        )
        return translate * rotate * scale
    }
}
