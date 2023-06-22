module MyCosmology

using QuadGK, Roots, Unitful
import Unitful: km, s, Gyr, K, Temperature, DimensionlessQuantity, Density
using UnitfulAstro: Mpc, Gpc, Msun
import PhysicalConstants.CODATA2018: c_0, G as G_NEWTON


export PLANCK18, FLRW

@derived_dimension Mode dimension(1/km)

abstract type Cosmology{T<:Real} end
abstract type FLRW{T<:Real} <: Cosmology{T} end

# Define a structure for FlatFLRW
struct FlatFLRW{T<:Real} <: FLRW{T}
    
    # Hubble parameter
    h::T 

    # Abundances of the different components
    Ω_χ0::T
    Ω_b0::T
    Ω_m0::T
    Ω_r0::T
    Ω_γ0::T
    Ω_ν0::T
    Ω_Λ0::T

    # Derived quantities
    z_eq_mr::T
    z_eq_Λm::T
    
    # Quantity with units
    ρ_c0_Msun_Mpc3::T
    T0_CMB_K::T

end

# First definition of the abundances
Ω_m(z::Real, Ω_m0::Real, Ω_r0::Real, Ω_Λ0::Real) = Ω_m0 * (1+z)^3 / (Ω_m0 * (1+z)^3 + Ω_r0 * (1+z)^4 + Ω_Λ0)
Ω_r(z::Real, Ω_m0::Real, Ω_r0::Real, Ω_Λ0::Real) = Ω_r0 * (1+z)^4 / (Ω_m0 * (1+z)^3 + Ω_r0 * (1+z)^4 + Ω_Λ0)
Ω_Λ(z::Real, Ω_m0::Real, Ω_r0::Real, Ω_Λ0::Real) = Ω_Λ0  / (Ω_m0 * (1+z)^3 + Ω_r0 * (1+z)^4 + Ω_Λ0)

# Constructor of the FlatBaseLCDM structure
function FlatFLRW(h::Real, Ω_χ0::Real, Ω_b0::Real; T0_CMB_K::Real = 2.72548, Neff::Real = 3.04)
    
    # Derived abundances
    Ω_γ0 = 4.48131e-7 * T0_CMB_K^4 / h^2
    Ω_ν0 = Neff * Ω_γ0 * (7 / 8) * (4 / 11)^(4 / 3)
    Ω_r0 = Ω_γ0 + Ω_ν0
    Ω_m0 = Ω_χ0 + Ω_b0
    Ω_Λ0 = 1 - Ω_m0 - Ω_r0
 
    ρ_c0_Msun_Mpc3 =  3/(8*π*G_NEWTON) * (100 * h * km / s / Mpc )^2 / (Msun / Mpc^3)

    z_eq_mr = 0.0
    z_eq_Λm = 0.0

    try
        z_eq_mr = exp(find_zero( y -> Ω_r(exp(y), Ω_m0, Ω_r0, Ω_Λ0) - Ω_m(exp(y), Ω_m0, Ω_r0, Ω_Λ0), (-10, 10), Bisection())) 
        z_eq_Λm = exp(find_zero( y -> Ω_Λ(exp(y), Ω_m0, Ω_r0, Ω_Λ0) - Ω_m(exp(y), Ω_m0, Ω_r0, Ω_Λ0), (-10, 10), Bisection())) 
    catch e
        println("Impossible to definez z_eq_mr and/or z_eq_Λm for this cosmology")
        println("Error: ", e)
    end

    return FlatFLRW(promote(h, Ω_χ0, Ω_b0, Ω_m0, Ω_r0, Ω_γ0, Ω_ν0, Ω_Λ0, z_eq_mr, z_eq_Λm, ρ_c0_Msun_Mpc3, T0_CMB_K)...) 
end

#########################################################
# global constant defining the cosmology used
const PLANCK18::FlatFLRW = FlatFLRW(0.6736, 0.26447, 0.04930)
const EDSPLANCK18::FlatFLRW  = FlatFLRW(0.6736, 0.3, 0) 
#########################################################

#########################################################
# Definition of the densities

""" CMB temperature (in K) of the Universe at redshift `z` (by default z=0) for the cosmology `cosmo` """
temperature_CMB_K(;z::Real = 0, cosmo::Cosmology = PLANCK18)::Real  = cosmo.T0_CMB_K * (1+z)

""" Hubble constant H0 (in km/s/Mpc) for the cosmology `cosmo` """
hubble_constant(cosmo::Cosmology = PLANCK18)::Real = 100 * cosmo.h

""" Hubble evolution (no dimension) of the Universe at redshift `z` (by default z=0) for the cosmology `cosmo` """
hubble_evolution(z::Real = 0, cosmo::Cosmology = PLANCK18)::Real = sqrt(cosmo.Ω_m0 * (1+z)^3 + cosmo.Ω_r0 * (1+z)^4 + cosmo.Ω_Λ0)

""" Hubble rate H(z) (in km/s/Mpc) of the Universe at redshift `z` (by default z=0) for the cosmology `cosmo` """
hubble_rate(z::Real = 0, cosmo::Cosmology = PLANCK18):: Real = hubble_evolution(z, cosmo) .* hubble_constant(cosmo) 
#########################################################

#########################################################
# Definition of the densities
# All densities are in units of Msun / Mpc^3 

""" Critical density (in Msun/Mpc^3) of the Universe at redshift `z` (by default z=0) for the cosmology `cosmo` """
ρ_c_Msun_Mpc3(z::Real = 0, cosmo::Cosmology = PLANCK18)::Real = cosmo.ρ_c0_Msun_Mpc3 * (cosmo.Ω_m0 * (1+z)^3 + cosmo.Ω_r0 * (1+z)^4 + cosmo.Ω_Λ0)

""" Radiation density (in Msun/Mpc^3) of the Universe at redshift `z` (by default z=0) for the cosmology `cosmo` """
ρ_r_Msun_Mpc3(z::Real = 0, cosmo::Cosmology = PLANCK18)::Real = cosmo.Ω_r0 * cosmo.ρ_c0_Msun_Mpc3 * (1+z)^4

""" Photon density (in Msun/Mpc^3) of the Universe at redshift `z` (by default z=0) for the cosmology `cosmo` """
ρ_γ_Msun_Mpc3(z::Real = 0, cosmo::Cosmology = PLANCK18)::Real = cosmo.Ω_γ0 * cosmo.ρ_c0_Msun_Mpc3 * (1+z)^4

""" Neutrino density (in Msun/Mpc^3) of the Universe at redshift `z` (by default z=0) for the cosmology `cosmo` """
ρ_ν_Msun_Mpc3(z::Real = 0, cosmo::Cosmology = PLANCK18)::Real = cosmo.Ω_ν0 * cosmo.ρ_c0_Msun_Mpc3 * (1+z)^4

""" Matter density (in Msun/Mpc^3) of the Universe at redshift `z` (by default z=0) for the cosmology `cosmo` """
ρ_m_Msun_Mpc3(z::Real = 0, cosmo::Cosmology = PLANCK18)::Real = cosmo.Ω_m0 * cosmo.ρ_c0_Msun_Mpc3 * (1+z)^3

""" Cold dark matter density (in Msun/Mpc^3) of the Universe at redshift `z` (by default z=0) for the cosmology `cosmo` """
ρ_χ_Msun_Mpc3(z::Real = 0, cosmo::Cosmology = PLANCK18)::Real = cosmo.Ω_χ0 * cosmo.ρ_c0_Msun_Mpc3 * (1+z)^3

""" Baryon density (in Msun/Mpc^3) of the Universe at redshift `z` (by default z=0) for the cosmology `cosmo` """
ρ_b_Msun_Mpc3(z::Real = 0, cosmo::Cosmology = PLANCK18)::Real = cosmo.Ω_b0 * cosmo.ρ_c0_Msun_Mpc3 * (1+z)^3

""" Cosmological constant density (in Msun/Mpc^3) of the Universe at redshift `z` (by default z=0) for the cosmology `cosmo` """
ρ_Λ_Msun_Mpc3(z::Real = 0, cosmo::Cosmology = PLANCK18)::Real = cosmo.Ω_Λ0 * cosmo.ρ_c0_Msun_Mpc3
#########################################################

#########################################################
# Definition of the abundances
Ω_r(z::Real = 0, cosmo::Cosmology = PLANCK18)::Real = (cosmo.Ω_r0 * (1+z)^4) / (cosmo.Ω_m0 * (1+z)^3 + cosmo.Ω_r0 * (1+z)^4 + cosmo.Ω_Λ0)
Ω_γ(z::Real = 0, cosmo::Cosmology = PLANCK18)::Real = (cosmo.Ω_γ0 * (1+z)^4) / (cosmo.Ω_m0 * (1+z)^3 + cosmo.Ω_r0 * (1+z)^4 + cosmo.Ω_Λ0)
Ω_ν(z::Real = 0, cosmo::Cosmology = PLANCK18)::Real = (cosmo.Ω_ν0 * (1+z)^4) / (cosmo.Ω_m0 * (1+z)^3 + cosmo.Ω_r0 * (1+z)^4 + cosmo.Ω_Λ0)
Ω_m(z::Real = 0, cosmo::Cosmology = PLANCK18)::Real = (cosmo.Ω_m0 * (1+z)^3) / (cosmo.Ω_m0 * (1+z)^3 + cosmo.Ω_r0 * (1+z)^4 + cosmo.Ω_Λ0)
Ω_χ(z::Real = 0, cosmo::Cosmology = PLANCK18)::Real = (cosmo.Ω_χ0 * (1+z)^3) / (cosmo.Ω_m0 * (1+z)^3 + cosmo.Ω_r0 * (1+z)^4 + cosmo.Ω_Λ0)
Ω_b(z::Real = 0, cosmo::Cosmology = PLANCK18)::Real = (cosmo.Ω_b0 * (1+z)^4) / (cosmo.Ω_m0 * (1+z)^3 + cosmo.Ω_r0 * (1+z)^4 + cosmo.Ω_Λ0)
Ω_Λ(z::Real = 0, cosmo::Cosmology = PLANCK18)::Real = cosmo.Ω_Λ0 / (cosmo.Ω_m0 * (1+z)^3 + cosmo.Ω_r0 * (1+z)^4 + cosmo.Ω_Λ0)
#########################################################

#########################################################
# Definition of specific time quantities
z_to_a(z::Real)::Real = 1 /(1 + z)
a_to_z(a::Real)::Real = 1 / a - 1
z_eq_mr(cosmo::Cosmology = PLANCK18)::Real = cosmo.z_eq_mr
z_eq_Λm(cosmo::Cosmology = PLANCK18)::Real = cosmo.z_eq_Λm
a_eq_mr(cosmo::Cosmology = PLANCK18)::Real = z_to_a(cosmo.z_eq_mr)
a_eq_Λm(cosmo::Cosmology = PLANCK18)::Real = z_to_a(cosmo.z_eq_Λm)
δt_s(a0, a1, cosmo::Cosmology = PLANCK18; kws...)::Real = QuadGK.quadgk(a -> 1 / hubble_evolution(a_to_z(a), cosmo) / a, a0, a1, rtol=1e-3; kws...)[1] / (hubble_constant(cosmo) * km / Mpc)
age(z=0, cosmo::Cosmology = PLANCK18; kws...)::Real = δt_s(0, z_to_a(z), cosmo; kws...)
lookback_time(z, cosmo::Cosmology = PLANCK18; kws...)::Real = δt_s(z_to_a(z), 1, cosmo; kws...)
#########################################################


end # module Cosmology
