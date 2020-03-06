mutable struct Rotational1{T,Nc} <: Joint{T,Nc}
    V12::SMatrix{2,3,T,6}
    V3::Adjoint{T,SVector{3,T}}
    cid::Int64

    function Rotational1(body1::AbstractBody{T}, body2::AbstractBody{T}, axis::AbstractVector{T}) where T
        Nc = 2

        axis = axis / norm(axis)
        A = Array(svd(skew(axis)).Vt)
        V12 = A[1:2,:]
        V3 = axis' # A[3,:] for correct sign
        cid = body2.id

        new{T,Nc}(V12, V3, cid), body1.id, body2.id
    end
end

@inline function minimalCoordinates(joint::Rotational1, body1::Body, body2::Body, dt, No)
    q = body1.q[No]\body2.q[No]
    joint.V3*axis(q)*angle(q)
end

@inline g(joint::Rotational1, body1::Body, body2::Body, dt, No) = joint.V12 * (VLᵀmat(getq3(body1, dt)) * getq3(body2, dt))

@inline function ∂g∂posa(joint::Rotational1{T}, body1::Body, body2::Body, No) where T
    if body2.id == joint.cid
        X = @SMatrix zeros(T, 2, 3)

        R = -joint.V12 * VRmat(body2.q[No]) * RᵀVᵀmat(body1.q[No])

        return [X R]
    else
        return ∂g∂posa(joint)
    end
end

@inline function ∂g∂posb(joint::Rotational1{T}, body1::Body, body2::Body, No) where T
    if body2.id == joint.cid
        X = @SMatrix zeros(T, 2, 3)

        R = joint.V12 * VLᵀmat(body1.q[No]) * LVᵀmat(body2.q[No])

        return [X R]
    else
        return ∂g∂posb(joint)
    end
end

@inline function ∂g∂vela(joint::Rotational1{T}, body1::Body, body2::Body, dt, No) where T
    if body2.id == joint.cid
        V = @SMatrix zeros(T, 2, 3)

        Ω = joint.V12 * VRmat(ωbar(body2, dt)) * Rmat(body2.q[No]) * Rᵀmat(body1.q[No]) * Tmat(T) * derivωbar(body1, dt)

        return [V Ω]
    else
        return ∂g∂vela(joint)
    end
end

@inline function ∂g∂velb(joint::Rotational1{T}, body1::Body, body2::Body, dt, No) where T
    if body2.id == joint.cid
        V = @SMatrix zeros(T, 2, 3)

        Ω = joint.V12 * VLᵀmat(ωbar(body1, dt)) * Lᵀmat(body1.q[No]) * Lmat(body2.q[No]) * derivωbar(body2, dt)

        return [V Ω]
    else
        return ∂g∂velb(joint)
    end
end


@inline function minimalCoordinates(joint::Rotational1, body1::Origin, body2::Body, dt, No)
    q = body2.q[No]
    joint.V3*axis(q)*angle(q) 
end

@inline g(joint::Rotational1, body1::Origin, body2::Body, dt, No) = joint.V12 * Vmat(getq3(body2, dt))

@inline function ∂g∂posb(joint::Rotational1{T}, body1::Origin, body2::Body, No) where T
    if body2.id == joint.cid
        X = @SMatrix zeros(T, 2, 3)

        R = joint.V12 * VLmat(body2.q[No]) * Vᵀmat(T)

        return [X R]
    else
        return ∂g∂posb(joint)
    end
end

@inline function ∂g∂velb(joint::Rotational1{T}, body1::Origin, body2::Body, dt, No) where T
    if body2.id == joint.cid
        V = @SMatrix zeros(T, 2, 3)

        Ω = joint.V12 * VLmat(body2.q[No]) * derivωbar(body2, dt)

        return [V Ω]
    else
        return ∂g∂velb(joint)
    end
end
