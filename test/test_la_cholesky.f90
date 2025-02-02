! Test Cholesky factorization
module test_linalg_cholesky
    use linear_algebra
    implicit none(type,external)
    private
    
    public :: test_cholesky_factorization

    contains

    !> Cholesky factorization tests
    subroutine test_cholesky_factorization(tests)
        !> Collection of tests
        logical,intent(out) :: error

        real :: t0,t1

        call cpu_time(t0)
        
        call test_cholesky_s(error)
        if (error) return
        call test_cholesky_d(error)
        if (error) return
        call test_cholesky_q(error)
        if (error) return
        call test_cholesky_c(error)
        if (error) return
        call test_cholesky_z(error)
        if (error) return
        call test_cholesky_w(error)
        if (error) return

        call cpu_time(t1)

        print 1,1000*(t1 - t0),merge('SUCCESS','ERROR  ',.not. error)

1       format('Cholesky factorization tests completed in ',f9.4,' milliseconds, result=',a)

    end subroutine test_cholesky_factorization

    !> Cholesky factorization of a random matrix
    subroutine test_cholesky_s(error)
        logical,intent(out) :: error

        integer(ilp),parameter :: n = 3_ilp
        real(sp),parameter :: tol = 100*sqrt(epsilon(0.0_sp))
        real(sp) :: a(n,n),l(n,n)
        type(la_state) :: state
        
        ! Set real matrix
        a(1,:) = [6,15,55]
        a(2,:) = [15,55,225]
        a(3,:) = [55,225,979]
        
        ! Set result (lower factor)
        l(1,:) = [2.4495_sp,0.0000_sp,0.0000_sp]
        l(2,:) = [6.1237_sp,4.1833_sp,0.0000_sp]
        l(3,:) = [22.4537_sp,20.9165_sp,6.1101_sp]
        
        ! 1) Cholesky factorization with full matrices
        call cholesky(a,l,other_zeroed=.true.,err=state)
        
        error = .not. state%ok()
        if (error) then
            print *, 'cholesky (subr) :: '//state%print()
            return
        end if
        
        error = .not. all(abs(a - matmul(l,transpose(l))) < tol)
        if (error) then
            print *, 'cholesky (subr) :: data converged'
            return
        end if
        
        ! 2) Function interface
        l = chol(a,other_zeroed=.true.)
        
        error = .not. all(abs(a - matmul(l,transpose(l))) < tol)
        if (error) then
            print *, 'cholesky (function) :: data converged'
            return
        end if
        
    end subroutine test_cholesky_s

    subroutine test_cholesky_d(error)
        logical,intent(out) :: error

        integer(ilp),parameter :: n = 3_ilp
        real(dp),parameter :: tol = 100*sqrt(epsilon(0.0_dp))
        real(dp) :: a(n,n),l(n,n)
        type(la_state) :: state
        
        ! Set real matrix
        a(1,:) = [6,15,55]
        a(2,:) = [15,55,225]
        a(3,:) = [55,225,979]
        
        ! Set result (lower factor)
        l(1,:) = [2.4495_dp,0.0000_dp,0.0000_dp]
        l(2,:) = [6.1237_dp,4.1833_dp,0.0000_dp]
        l(3,:) = [22.4537_dp,20.9165_dp,6.1101_dp]
        
        ! 1) Cholesky factorization with full matrices
        call cholesky(a,l,other_zeroed=.true.,err=state)
        
        error = .not. state%ok()
        if (error) then
            print *, 'cholesky (subr) :: '//state%print()
            return
        end if
        
        error = .not. all(abs(a - matmul(l,transpose(l))) < tol)
        if (error) then
            print *, 'cholesky (subr) :: data converged'
            return
        end if
        
        ! 2) Function interface
        l = chol(a,other_zeroed=.true.)
        
        error = .not. all(abs(a - matmul(l,transpose(l))) < tol)
        if (error) then
            print *, 'cholesky (function) :: data converged'
            return
        end if
        
    end subroutine test_cholesky_d

    subroutine test_cholesky_q(error)
        logical,intent(out) :: error

        integer(ilp),parameter :: n = 3_ilp
        real(qp),parameter :: tol = 100*sqrt(epsilon(0.0_qp))
        real(qp) :: a(n,n),l(n,n)
        type(la_state) :: state
        
        ! Set real matrix
        a(1,:) = [6,15,55]
        a(2,:) = [15,55,225]
        a(3,:) = [55,225,979]
        
        ! Set result (lower factor)
        l(1,:) = [2.4495_qp,0.0000_qp,0.0000_qp]
        l(2,:) = [6.1237_qp,4.1833_qp,0.0000_qp]
        l(3,:) = [22.4537_qp,20.9165_qp,6.1101_qp]
        
        ! 1) Cholesky factorization with full matrices
        call cholesky(a,l,other_zeroed=.true.,err=state)
        
        error = .not. state%ok()
        if (error) then
            print *, 'cholesky (subr) :: '//state%print()
            return
        end if
        
        error = .not. all(abs(a - matmul(l,transpose(l))) < tol)
        if (error) then
            print *, 'cholesky (subr) :: data converged'
            return
        end if
        
        ! 2) Function interface
        l = chol(a,other_zeroed=.true.)
        
        error = .not. all(abs(a - matmul(l,transpose(l))) < tol)
        if (error) then
            print *, 'cholesky (function) :: data converged'
            return
        end if
        
    end subroutine test_cholesky_q

    subroutine test_cholesky_c(error)
        logical,intent(out) :: error

        integer(ilp),parameter :: n = 3_ilp
        real(sp),parameter :: tol = 100*sqrt(epsilon(0.0_sp))
        complex(sp) :: a(n,n),l(n,n)
        type(la_state) :: state
        
        ! Set real matrix
        a(1,:) = [6,15,55]
        a(2,:) = [15,55,225]
        a(3,:) = [55,225,979]
        
        ! Set result (lower factor)
        l(1,:) = [2.4495_sp,0.0000_sp,0.0000_sp]
        l(2,:) = [6.1237_sp,4.1833_sp,0.0000_sp]
        l(3,:) = [22.4537_sp,20.9165_sp,6.1101_sp]
        
        ! 1) Cholesky factorization with full matrices
        call cholesky(a,l,other_zeroed=.true.,err=state)
        
        error = .not. state%ok()
        if (error) then
            print *, 'cholesky (subr) :: '//state%print()
            return
        end if
        
        error = .not. all(abs(a - matmul(l,transpose(l))) < tol)
        if (error) then
            print *, 'cholesky (subr) :: data converged'
            return
        end if
        
        ! 2) Function interface
        l = chol(a,other_zeroed=.true.)
        
        error = .not. all(abs(a - matmul(l,transpose(l))) < tol)
        if (error) then
            print *, 'cholesky (function) :: data converged'
            return
        end if
        
    end subroutine test_cholesky_c

    subroutine test_cholesky_z(error)
        logical,intent(out) :: error

        integer(ilp),parameter :: n = 3_ilp
        real(dp),parameter :: tol = 100*sqrt(epsilon(0.0_dp))
        complex(dp) :: a(n,n),l(n,n)
        type(la_state) :: state
        
        ! Set real matrix
        a(1,:) = [6,15,55]
        a(2,:) = [15,55,225]
        a(3,:) = [55,225,979]
        
        ! Set result (lower factor)
        l(1,:) = [2.4495_dp,0.0000_dp,0.0000_dp]
        l(2,:) = [6.1237_dp,4.1833_dp,0.0000_dp]
        l(3,:) = [22.4537_dp,20.9165_dp,6.1101_dp]
        
        ! 1) Cholesky factorization with full matrices
        call cholesky(a,l,other_zeroed=.true.,err=state)
        
        error = .not. state%ok()
        if (error) then
            print *, 'cholesky (subr) :: '//state%print()
            return
        end if
        
        error = .not. all(abs(a - matmul(l,transpose(l))) < tol)
        if (error) then
            print *, 'cholesky (subr) :: data converged'
            return
        end if
        
        ! 2) Function interface
        l = chol(a,other_zeroed=.true.)
        
        error = .not. all(abs(a - matmul(l,transpose(l))) < tol)
        if (error) then
            print *, 'cholesky (function) :: data converged'
            return
        end if
        
    end subroutine test_cholesky_z

    subroutine test_cholesky_w(error)
        logical,intent(out) :: error

        integer(ilp),parameter :: n = 3_ilp
        real(qp),parameter :: tol = 100*sqrt(epsilon(0.0_qp))
        complex(qp) :: a(n,n),l(n,n)
        type(la_state) :: state
        
        ! Set real matrix
        a(1,:) = [6,15,55]
        a(2,:) = [15,55,225]
        a(3,:) = [55,225,979]
        
        ! Set result (lower factor)
        l(1,:) = [2.4495_qp,0.0000_qp,0.0000_qp]
        l(2,:) = [6.1237_qp,4.1833_qp,0.0000_qp]
        l(3,:) = [22.4537_qp,20.9165_qp,6.1101_qp]
        
        ! 1) Cholesky factorization with full matrices
        call cholesky(a,l,other_zeroed=.true.,err=state)
        
        error = .not. state%ok()
        if (error) then
            print *, 'cholesky (subr) :: '//state%print()
            return
        end if
        
        error = .not. all(abs(a - matmul(l,transpose(l))) < tol)
        if (error) then
            print *, 'cholesky (subr) :: data converged'
            return
        end if
        
        ! 2) Function interface
        l = chol(a,other_zeroed=.true.)
        
        error = .not. all(abs(a - matmul(l,transpose(l))) < tol)
        if (error) then
            print *, 'cholesky (function) :: data converged'
            return
        end if
        
    end subroutine test_cholesky_w

end module test_linalg_cholesky
