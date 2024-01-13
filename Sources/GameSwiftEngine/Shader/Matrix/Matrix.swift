import simd

public func perspectiveMatrix(
    fovyRadians fovy: GEFloat = 65 * 3.141_592 / 180.0,
    aspectRatio: GEFloat,
    nearZ: GEFloat = 0.1,
    farZ: GEFloat = 100
) -> matrix_float4x4 {
    let yScale = 1 / tanf(fovy * 0.5)
    let xScale = yScale / aspectRatio
    let zScale = farZ / (nearZ - farZ)
    return matrix_float4x4(
        columns: (
            vector_float4(xScale, 0, 0, 0),
            vector_float4(0, yScale, 0, 0),
            vector_float4(0, 0, zScale, -1),
            vector_float4(0, 0, nearZ * zScale, 0)
        )
    )
}

/// Provides a rotation matrix using the SIMD library.
public func rotationMatrix4x4(radians: GEFloat, axis: vector_float3) -> matrix_float4x4 {
    let unitAxis = normalize(axis)
    let cosTheta = cosf(radians)
    let sinTheta = sinf(radians)
    let oneMinusCosTheta = 1 - cosTheta

    let m11 = cosTheta + unitAxis.x * unitAxis.x * oneMinusCosTheta
    let m21 = unitAxis.y * unitAxis.x * oneMinusCosTheta + unitAxis.z * sinTheta
    let m31 = unitAxis.z * unitAxis.x * oneMinusCosTheta - unitAxis.y * sinTheta
    let m12 = unitAxis.x * unitAxis.y * oneMinusCosTheta - unitAxis.z * sinTheta
    let m22 = cosTheta + unitAxis.y * unitAxis.y * oneMinusCosTheta
    let m32 = unitAxis.z * unitAxis.y * oneMinusCosTheta + unitAxis.x * sinTheta
    let m13 = unitAxis.x * unitAxis.z * oneMinusCosTheta + unitAxis.y * sinTheta
    let m23 = unitAxis.y * unitAxis.z * oneMinusCosTheta - unitAxis.x * sinTheta
    let m33 = cosTheta + unitAxis.z * unitAxis.z * oneMinusCosTheta

    return matrix_float4x4(
        columns: (
            vector_float4(m11, m21, m31, 0),
            vector_float4(m12, m22, m32, 0),
            vector_float4(m13, m23, m33, 0),
            vector_float4(0, 0, 0, 1)
        )
    )
}

/// Provides a translation matrix using the SIMD library.
public func translationMatrix4x4(_ translationX: GEFloat, _ translationY: GEFloat, _ translationZ: GEFloat) -> matrix_float4x4 {
    return matrix_float4x4(
        columns: (
            vector_float4(1, 0, 0, 0),
            vector_float4(0, 1, 0, 0),
            vector_float4(0, 0, 1, 0),
            vector_float4(translationX, translationY, translationZ, 1)
        )
    )
}

func absalutePositionColisionInPlane(
    position: vector_float4,
    radius: GEFloat = 1,
    planeSize: vector_float2 = .one,
    planeTransform: matrix_float4x4 // default plane in z x
) -> vector_float4? {
    var position = position
    position = matrix_multiply(planeTransform.inverse, position)
    guard abs(position.x) < planeSize.x / 2 else {
        return nil
    }
    guard abs(position.z) < planeSize.y / 2 else {
        return nil
    }
    let lng = position.y
    guard lng > 0 && lng < radius else {
        return nil
    }
    var result = vector_float4(position.x, radius, position.z, 1)
    result = matrix_multiply(planeTransform, result)
    return result
}

//matrix_float4x4(
//    columns: (
//        vector_float4(xScale, 0, 0, 0),
//        vector_float4(0, yScale, 0, 0),
//        vector_float4(0, 0, zScale, -1),
//        vector_float4(0, 0, zScale * nearZ, 0)
//    )
//)
//
//matrix_float4x4(
//    rows: ( 1
//            vector_float4(xScale, 0, 0, 0),
//            vector_float4(0, yScale, 0, 0),
//            vector_float4(0, 0, zScale, -1),
//            vector_float4(0, 0, zScale * nearZ, 0)
//    )
//)
//
//float posiztionZ = (position.z + lights[i].shadowShiftZ) / position.w;
//
//
//out.x   = (in.x * xScale) / (in.z * -1);
//out.z   = (in.z * zScale + zScale * nearZ) / (in.z * -1);
//out.w   = in.z * -1 ;
//
//
//
