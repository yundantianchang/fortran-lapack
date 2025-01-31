# fortran-lapack
This package provides precision-agnostic, high-level linear algebra APIs for `real` and `complex` arguments in Modern Fortran. The APIs are similar to NumPy/SciPy operations, and leverage a Modern Fortran implementation of the [Reference-LAPACK](http://github.com/reference-LAPACK) library.

A full and standardized implementation of the present library has been integrated into the [Fortran Standard Library](http://stdlib.fortran-lang.org/), and as such, most users should seek to access the functionality from `stdlib`. The present library is kept in place for those who seek a compact implementation of it.

# Browse API

## [`solve`](@ref la_solve::solve) - Solves a linear matrix equation or a linear system of equations.

### Syntax

`x = solve(a, b [, overwrite_a] [, err])`  

### Description

Solve linear systems - one (`b(:)`) or many (`b(:,:)`).  

### Arguments

- `a`: A `real` or `complex` coefficient matrix. If `overwrite_a=.true.`, it is destroyed by the call.
- `b`: A rank-1 (one system) or rank-2 (many systems) array of the same kind as `a`, containing the right-hand-side vector(s).
- `overwrite_a` (optional, default = `.false.`): If `.true.`, input matrix `a` will be used as temporary storage and overwritten, to avoid internal data allocation.
- `err` (optional): A [`type(la_state)`](@ref la_state_type::la_state) variable. 

### Return value

For a full-rank matrix, returns an array value that represents the solution to the linear system of equations.

### Errors

- Raises [`LINALG_ERROR`](@ref la_state_type::linalg_error) if the matrix is singular to working precision.
- Raises [`LINALG_VALUE_ERROR`](@ref la_state_type::linalg_value_error) if the matrix and rhs vectors have invalid/incompatible sizes.
- If `err` is not present, exceptions trigger an `error stop`.

## [`lstsq`](@ref la_least_squares::lstsq) - Computes a least squares solution to a system of linear equations.

### Syntax

`x = lstsq(a, b [, cond] [, overwrite_a] [, rank] [, err])`

### Description

Solves the least-squares problem for the system \f$ A \cdot x = b \f$, where \f$ A \f$ is a square matrix of size \f$ n \times n \f$ and \f$ b \f$ is either a vector of size \f$ n \f$ or a matrix of size \f$ n \times nrhs \f$. The function minimizes the 2-norm \f$ \|b - A \cdot x\| \f$ by solving for \f$ x \f$. 

The result \f$ x \f$ is returned as an allocatable array, and it is either a vector (for a single right-hand side) or a matrix (for multiple right-hand sides).

### Arguments

- `a`: A `real` matrix of size \f$ n \times n \f$ representing the coefficient matrix. If `overwrite_a = .true.`, the contents of `a` may be modified during the computation.
- `b`: A `real` vector or matrix representing the right-hand side. The size should be \f$ n \f$ (for a single right-hand side) or \f$ n \times nrhs \f$ (for multiple right-hand sides).
- `cond` (optional): A cutoff for rank evaluation. Singular values \f$ s(i) \f$ such that \f$ s(i) \leq \text{cond} \cdot \max(s) \f$ are considered zero. 
- `overwrite_a` (optional, default = `.false.`): If `.true.`, both `a` and `b` may be overwritten and destroyed during computation. 
- `rank` (optional): An integer variable that returns the rank of the matrix \f$ A \f$.
- `err` (optional): A [`type(la_state)`](@ref la_state_type::la_state) variable that returns the error state. If `err` is not provided, the function will stop execution on error.

### Return value

Returns the solution array \f$ x \f$ with size \f$ n \f$ (for a single right-hand side) or \f$ n \times nrhs \f$ (for multiple right-hand sides).

### Errors

- Raises [`LINALG_ERROR`](@ref la_state_type::linalg_error) if the matrix \f$ A \f$ is singular to working precision.
- Raises [`LINALG_VALUE_ERROR`](@ref la_state_type::linalg_value_error) if the matrix `a` and the right-hand side `b` have incompatible sizes.
- If `err` is not provided, the function stops execution on error.

### Notes

- This function relies on LAPACK's least-squares solvers, such as [`*GELSS`](@ref la_lapack::gelss).
- If `overwrite_a` is enabled, the original contents of `a` and `b` may be lost.

## `det(A)`
**Type**: Function  
**Description**: Determinant of a scalar or square matrix.  
**Optional arguments**:  
- `overwrite_a`: Option to let A be destroyed.  
- `err`: Return state handler.

## `inv(A)`
**Type**: Function  
**Description**: Inverse of a scalar or square matrix.  
**Optional arguments**:  
- `err`: Return state handler.

## `pinv(A)`
**Type**: Function  
**Description**: Moore-Penrose Pseudo-Inverse of a matrix.  
**Optional arguments**:  
- `rtol`: Optional singular value threshold.  
- `err`: Return state handler.

## `invert(A)`
**Type**: Subroutine  
**Description**: In-place inverse of a scalar or square matrix.  
**Optional arguments**:  
- `err`: Return state handler.  

**Usage**: `call invert(A, err=err)` where `A` is replaced with $A^{-1}$.

## `.inv.A`
**Type**: Operator  
**Description**: Inverse of a scalar or square matrix.  

**Effect**: `A` is replaced with $A^{-1}$.

## `.pinv.A`
**Type**: Operator  
**Description**: Moore-Penrose Pseudo-Inverse.  

**Effect**: `A` is replaced with $A^{-1}$.

## `svd(A)`
**Type**: Subroutine  
**Description**: Singular value decomposition of $A = U S V^t$.  
**Optional arguments**:  
- `s`: Singular values.  
- `u`: Left singular vectors.  
- `vt`: Right singular vectors.  
- `full_matrices`: Defaults to `.false.`.  
- `err`: State handler.  

**Usage**: `call svd(A, s, u, vt, full_matrices=.false., err=state)`.

## `svdvals(A)`
**Type**: Function  
**Description**: Singular values $S$ from $A = U S V^t$.  
**Usage**: `s = svdvals(A)` where `s` is a real array with the same precision as `A`.

## `eye(m)`
**Type**: Function  
**Description**: Identity matrix of size `m`.  
**Optional arguments**:  
- `n`: Optional column size.  
- `mold`: Optional datatype (default: real64).  
- `err`: Error handler.

## `eigvals(A)`
**Type**: Function  
**Description**: Eigenvalues of matrix $A$.  
**Optional arguments**:  
- `err`: State handler.

## `eig(A, lambda)`
**Type**: Subroutine  
**Description**: Eigenproblem of matrix $A`.  
**Optional arguments**:  
- `left`: Output left eigenvector matrix.  
- `right`: Output right eigenvector matrix.  
- `overwrite_a`: Option to let A be destroyed.  
- `err`: Return state handler.

## `eigvalsh(A)`
**Type**: Function  
**Description**: Eigenvalues of symmetric or Hermitian matrix $A$.  
**Optional arguments**:  
- `upper_a`: Choose to use upper or lower triangle.  
- `err`: State handler.

## `eigh(A, lambda)`
**Type**: Subroutine  
**Description**: Eigenproblem of symmetric or Hermitian matrix $A`.  
**Optional arguments**:  
- `vector`: Output eigenvectors.  
- `upper_a`: Choose to use upper or lower triangle.  
- `overwrite_a`: Option to let A be destroyed.  
- `err`: Return state handler.

## `diag(n, source)`
**Type**: Function  
**Description**: Diagonal matrix from scalar input value.  
**Optional arguments**:  
- `err`: Error handler.

## `diag(source)`
**Type**: Function  
**Description**: Diagonal matrix from array input values.  
**Optional arguments**:  
- `err`: Error handler.

## `qr(A, Q, R)`
**Type**: Subroutine  
**Description**: QR factorization.  
**Optional arguments**:  
- `storage`: Pre-allocated working storage.  
- `err`: Error handler.

## `qr_space(A, lwork)`
**Type**: Subroutine  
**Description**: QR Working space size.  
**Optional arguments**:  
- `err`: Error handler.

All procedures work with all types (`real`, `complex`) and kinds (32, 64, 128-bit floats).

# BLAS, LAPACK
Modern Fortran modules with full explicit typing features are available as modules `la_blas` and `la_lapack`. 
The reference Fortran-77 library, forked from Release 3.10.1, was automatically processed and modernized.
The following refactorings are applied: 
- All datatypes and accuracy constants standardized into a module (`stdlib`-compatible names)
- Both libraries available for 32, 64 and 128-bit floats
- Free format, lower-case style
- `implicit none(type, external)` everywhere
- all `pure` procedures where possible
- `intent` added to all procedure arguments
- Removed `DO 10 .... 10 CONTINUE`, replaced with `do..end do` loops or labelled `loop_10: do ... cycle loop_10 ... end do loop_10` in case control statements are present
- BLAS modularized into a single-file module
- LAPACK modularized into a single-file module
- All procedures prefixed (with `stdlib_`, currently).
- F77-style `parameter`s removed, and numeric constants moved to the top of each module.
- Ambiguity in single vs. double precision constants (`0.0`, `0.d0`, `(1.0,0.0)`) removed
- preprocessor-based OpenMP directives retained.

The single-source module structure hopefully allows for cross-procedural inlining which is otherwise impossible without link-time optimization.

# Building
An automated build is currently available via the [Fortran Package Manager](https://fpm.fortran-lang.org).
To add fortran-lapack to your project, simply add it as a dependency: 

```
[dependencies]
fortran-lapack = { git="https://github.com/perazz/fortran-lapack.git" }
```

`fortran-lapack` is compatible with the LAPACK API. If high-performance external BLAS/LAPACK libraries are available, it is sufficient to define macros

```
[dependencies]
fortran-lapack = { git="https://github.com/perazz/fortran-lapack.git", preprocess.cpp.macros=["LA_EXTERNAL_BLAS", "LA_EXTERNAL_LAPACK"] }
```

# Extension to external BLAS/LAPACK libraries

Generic interfaces to most BLAS/LAPACK functions are exposed to modules `la_blas` and `la_lapack`. These interfaces drop the initial letter to wrap a precision-agnostic version. For example, `axpy` is a precision-agnostic interface to `saxpy`, `daxpy`, `caxpy`, `zaxpy`, `qaxpy`, `waxpy`. 
The naming convention is: 

Type     | 32-bit | 64-bit | 128-bit
---      | ---    | ---    | --- 
real     | `s`    | `d`    | `q`
complex  | `c`    | `z`    | `w`

All public interfaces in `la_blas` and `la_lapack` allow seamless linking against external libraries via a simple pre-processor flag. 
When an external library is available, just define macros `LA_EXTERNAL_BLAS` and `LA_EXTERNAL_LAPACK`. The kind-agnostic interface
will just point to the external function. All such interfaces follow this template:  

```fortran  
interface axpy
#ifdef LA_EXTERNAL_BLAS
    ! Use external library
    pure subroutine saxpy(n, a, x, incx, y, incy)
      import :: ik, sp
      integer, parameter :: wp = sp
      integer(ik), intent(in) :: n
      real(wp), intent(in) :: a
      real(wp), intent(in) :: x(*)
      integer(ik), intent(in) :: incx
      real(wp), intent(inout) :: y(*)
      integer(ik), intent(in) :: incy
    end subroutine saxpy
#else
    ! Use internal implementation
    module procedure la_saxpy
#endif
end interface
```

# Licensing

LAPACK is a freely-available software package. It is available from [netlib](https://www.netlib.org/lapack/) via anonymous ftp and the World Wide Web. Thus, it can be included in commercial software packages (and has been). Credit for the library should be given to the [LAPACK authors](https://www.netlib.org/lapack/contributor-list.html).
The license used for the software is the [modified BSD license](https://www.netlib.org/lapack/LICENSE.txt).
According to the original license, we changed the name of the routines and commented the changes made to the original.

# Acknowledgments
Part of this work was supported by the [Sovereign Tech Fund](https://www.sovereigntechfund.de).
