module la_eig
     use la_constants
     use la_blas
     use la_lapack
     use la_state_type
     use,intrinsic :: ieee_arithmetic,only:ieee_value,ieee_positive_inf,ieee_quiet_nan
     implicit none(type,external)
     private

     !> Eigendecomposition of a square matrix: return eigenvalues, and optionally eigenvectors
     public :: eig
     !> Eigenvalues of a square matrix
     public :: eigvals
     !> Eigendecomposition of a real symmetric or complex hermitian matrix
     public :: eigh
     !> Eigenvalues of a real symmetric or complex hermitian matrix
     public :: eigvalsh

     ! Numpy: eigenvalues, eigenvectors = eig(a)
     !        eigenvalues = eigvals(a)
     ! Scipy: eig(a, b=None, left=False, right=True, overwrite_a=False, overwrite_b=False, check_finite=True, homogeneous_eigvals=False)

     ! Numpy: eigenvalues, eigenvectors = eigh(a, uplo='L')
     !        eigenvalues = eigvalsh(a)
     ! Scipy: eigh(a, b=None, *, lower=True, eigvals_only=False, overwrite_a=False, overwrite_b=False, turbo=<object object>, eigvals=<object object>, type=1, check_finite=True, subset_by_index=None, subset_by_value=None, driver=None)

     interface eig
        module procedure la_eig_standard_s
        module procedure la_eig_standard_d
        module procedure la_eig_standard_q
        module procedure la_eig_standard_c
        module procedure la_eig_standard_z
        module procedure la_eig_standard_w
        module procedure la_real_eig_standard_s
        module procedure la_real_eig_standard_d
        module procedure la_real_eig_standard_q
        module procedure la_eig_generalized_s
        module procedure la_eig_generalized_d
        module procedure la_eig_generalized_q
        module procedure la_eig_generalized_c
        module procedure la_eig_generalized_z
        module procedure la_eig_generalized_w
        module procedure la_real_eig_generalized_s
        module procedure la_real_eig_generalized_d
        module procedure la_real_eig_generalized_q
     end interface eig

     interface eigvals
        module procedure la_eigvals_standard_s
        module procedure la_eigvals_noerr_standard_s
        module procedure la_eigvals_generalized_s
        module procedure la_eigvals_noerr_generalized_s
        module procedure la_eigvals_standard_d
        module procedure la_eigvals_noerr_standard_d
        module procedure la_eigvals_generalized_d
        module procedure la_eigvals_noerr_generalized_d
        module procedure la_eigvals_standard_q
        module procedure la_eigvals_noerr_standard_q
        module procedure la_eigvals_generalized_q
        module procedure la_eigvals_noerr_generalized_q
        module procedure la_eigvals_standard_c
        module procedure la_eigvals_noerr_standard_c
        module procedure la_eigvals_generalized_c
        module procedure la_eigvals_noerr_generalized_c
        module procedure la_eigvals_standard_z
        module procedure la_eigvals_noerr_standard_z
        module procedure la_eigvals_generalized_z
        module procedure la_eigvals_noerr_generalized_z
        module procedure la_eigvals_standard_w
        module procedure la_eigvals_noerr_standard_w
        module procedure la_eigvals_generalized_w
        module procedure la_eigvals_noerr_generalized_w
     end interface eigvals
     
     interface eigh
        module procedure la_eigh_s
        module procedure la_eigh_d
        module procedure la_eigh_q
        module procedure la_eigh_c
        module procedure la_eigh_z
        module procedure la_eigh_w
     end interface eigh
     
     interface eigvalsh
        module procedure la_eigvalsh_s
        module procedure la_eigvalsh_noerr_s
        module procedure la_eigvalsh_d
        module procedure la_eigvalsh_noerr_d
        module procedure la_eigvalsh_q
        module procedure la_eigvalsh_noerr_q
        module procedure la_eigvalsh_c
        module procedure la_eigvalsh_noerr_c
        module procedure la_eigvalsh_z
        module procedure la_eigvalsh_noerr_z
        module procedure la_eigvalsh_w
        module procedure la_eigvalsh_noerr_w
     end interface eigvalsh

     !> Utility function: Scale generalized eigenvalue
     interface scale_general_eig
        module procedure scale_general_eig_s
        module procedure scale_general_eig_d
        module procedure scale_general_eig_q
        module procedure scale_general_eig_c
        module procedure scale_general_eig_z
        module procedure scale_general_eig_w
     end interface scale_general_eig

     character(*),parameter :: this = 'eigenvalues'

     contains
     
     !> Request for eigenvector calculation
     elemental character function eigenvectors_task(required)
        logical(lk),intent(in) :: required
        eigenvectors_task = merge('V','N',required)
     end function eigenvectors_task
     
     !> Request for symmetry side (default: lower)
     elemental character function symmetric_triangle_task(upper)
        logical(lk),optional,intent(in) :: upper
        if (present(upper)) then
           symmetric_triangle_task = merge('U','L',upper)
        else
           symmetric_triangle_task = 'L'
        end if
     end function symmetric_triangle_task

     !> Process GEEV output flags
     pure subroutine handle_geev_info(err,info,shapea)
        !> Error handler
        type(la_state),intent(inout) :: err
        !> GEEV return flag
        integer(ilp),intent(in) :: info
        !> Input matrix size
        integer(ilp),intent(in) :: shapea(2)

        select case (info)
           case (0)
               ! Success!
               err%state = LINALG_SUCCESS
           case (-1)
               err = la_state(this,LINALG_INTERNAL_ERROR,'Invalid task ID: left eigenvectors.')
           case (-2)
               err = la_state(this,LINALG_INTERNAL_ERROR,'Invalid task ID: right eigenvectors.')
           case (-5,-3)
               err = la_state(this,LINALG_VALUE_ERROR,'invalid matrix size: a=',shapea)
           case (-9)
               err = la_state(this,LINALG_VALUE_ERROR,'insufficient left vector matrix size.')
           case (-11)
               err = la_state(this,LINALG_VALUE_ERROR,'insufficient right vector matrix size.')
           case (-13)
               err = la_state(this,LINALG_INTERNAL_ERROR,'Insufficient work array size.')
           case (1:)
               err = la_state(this,LINALG_ERROR,'Eigenvalue computation did not converge.')
           case default
               err = la_state(this,LINALG_INTERNAL_ERROR,'Unknown error returned by geev.')
        end select

     end subroutine handle_geev_info

     !> Process GGEV output flags
     pure subroutine handle_ggev_info(err,info,shapea,shapeb)
        !> Error handler
        type(la_state),intent(inout) :: err
        !> GEEV return flag
        integer(ilp),intent(in) :: info
        !> Input matrix size
        integer(ilp),intent(in) :: shapea(2),shapeb(2)

        select case (info)
           case (0)
               ! Success!
               err%state = LINALG_SUCCESS
           case (-1)
               err = la_state(this,LINALG_INTERNAL_ERROR,'Invalid task ID: left eigenvectors.')
           case (-2)
               err = la_state(this,LINALG_INTERNAL_ERROR,'Invalid task ID: right eigenvectors.')
           case (-5,-3)
               err = la_state(this,LINALG_VALUE_ERROR,'invalid matrix size: a=',shapea)
           case (-7)
               err = la_state(this,LINALG_VALUE_ERROR,'invalid matrix size: b=',shapeb)
           case (-12)
               err = la_state(this,LINALG_VALUE_ERROR,'insufficient left vector matrix size.')
           case (-14)
               err = la_state(this,LINALG_VALUE_ERROR,'insufficient right vector matrix size.')
           case (-16)
               err = la_state(this,LINALG_INTERNAL_ERROR,'Insufficient work array size.')
           case (1:)
               err = la_state(this,LINALG_ERROR,'Eigenvalue computation did not converge.')
           case default
               err = la_state(this,LINALG_INTERNAL_ERROR,'Unknown error returned by ggev.')
        end select

     end subroutine handle_ggev_info

     !> Process SYEV/HEEV output flags
     elemental subroutine heev_info(err,info,m,n)
        !> Error handler
        type(la_state),intent(inout) :: err
        !> geev return flag
        integer(ilp),intent(in) :: info
        !> Input matrix size
        integer(ilp),intent(in) :: m,n

        select case (info)
           case (0)
               ! Success!
               err%state = LINALG_SUCCESS
           case (-1)
               err = la_state(this,LINALG_INTERNAL_ERROR,'Invalid eigenvector request.')
           case (-2)
               err = la_state(this,LINALG_INTERNAL_ERROR,'Invalid triangular section request.')
           case (-5,-3)
               err = la_state(this,LINALG_VALUE_ERROR,'invalid matrix size: a=', [m,n])
           case (-8)
               err = la_state(this,LINALG_INTERNAL_ERROR,'insufficient workspace size.')
           case (1:)
               err = la_state(this,LINALG_ERROR,'Eigenvalue computation did not converge.')
           case default
               err = la_state(this,LINALG_INTERNAL_ERROR,'Unknown error returned by syev/heev.')
        end select

     end subroutine heev_info

     function la_eigvals_standard_s(a,err) result(lambda)
     !! Return an array of eigenvalues of matrix A.
         !> Input matrix A[m,n]
         real(sp),intent(in),dimension(:,:),target :: a
         !> [optional] state return flag. On error if not requested, the code will stop
         type(la_state),intent(out) :: err
         !> Array of eigenvalues
         complex(sp),allocatable :: lambda(:)

         !> Create
         real(sp),pointer,dimension(:,:) :: amat
         integer(ilp) :: m,n,k

         !> Create an internal pointer so the intent of A won't affect the next call
         amat => a
         
         m = size(a,1,kind=ilp)
         n = size(a,2,kind=ilp)
         k = min(m,n)

         !> Allocate return storage
         allocate (lambda(k))

         !> Compute eigenvalues only
         call la_eig_standard_s(amat,lambda,err=err)

     end function la_eigvals_standard_s

     function la_eigvals_noerr_standard_s(a) result(lambda)
     !! Return an array of eigenvalues of matrix A.
         !> Input matrix A[m,n]
         real(sp),intent(in),dimension(:,:),target :: a
         !> Array of eigenvalues
         complex(sp),allocatable :: lambda(:)

         !> Create
         real(sp),pointer,dimension(:,:) :: amat
         integer(ilp) :: m,n,k

         !> Create an internal pointer so the intent of A won't affect the next call
         amat => a
         
         m = size(a,1,kind=ilp)
         n = size(a,2,kind=ilp)
         k = min(m,n)

         !> Allocate return storage
         allocate (lambda(k))

         !> Compute eigenvalues only
         call la_eig_standard_s(amat,lambda,overwrite_a=.false.)

     end function la_eigvals_noerr_standard_s

     subroutine la_eig_standard_s(a,lambda,right,left, &
                                                       overwrite_a,err)
     !! Eigendecomposition of matrix A returning an array `lambda` of eigenvalues,
     !! and optionally right or left eigenvectors.
         !> Input matrix A[m,n]
         real(sp),intent(inout),dimension(:,:),target :: a
         !> Array of eigenvalues
         complex(sp),intent(out) :: lambda(:)
         !> [optional] RIGHT eigenvectors of A (as columns)
         complex(sp),optional,intent(out),target :: right(:,:)
         !> [optional] LEFT eigenvectors of A (as columns)
         complex(sp),optional,intent(out),target :: left(:,:)
         !> [optional] Can A data be overwritten and destroyed? (default: no)
         logical(lk),optional,intent(in) :: overwrite_a
         !> [optional] state return flag. On error if not requested, the code will stop
         type(la_state),optional,intent(out) :: err

         !> Local variables
         type(la_state) :: err0
         integer(ilp) :: m,n,lda,ldu,ldv,info,k,lwork,neig
         logical(lk) :: copy_a
         character :: task_u,task_v
         real(sp),target :: work_dummy(1),u_dummy(1,1),v_dummy(1,1)
         real(sp),allocatable :: work(:)
         real(sp),dimension(:,:),pointer :: amat,umat,vmat
         real(sp),pointer :: lreal(:),limag(:)
         
         !> Matrix size
         m = size(a,1,kind=ilp)
         n = size(a,2,kind=ilp)
         k = min(m,n)
         neig = size(lambda,kind=ilp)
         lda = m

         if (k <= 0 .or. m /= n) then
            err0 = la_state(this,LINALG_VALUE_ERROR, &
                                          'invalid or matrix size a=', [m,n],', must be nonempty square.')
            call err0%handle(err)
            return
         elseif (neig < k) then
            err0 = la_state(this,LINALG_VALUE_ERROR, &
                                          'eigenvalue array has insufficient size:', &
                                          ' lambda=',neig,', n=',n)
            call err0%handle(err)
            return
         end if
         
         ! Can A be overwritten? By default, do not overwrite
         copy_a = .true._lk
         if (present(overwrite_a)) copy_a = .not. overwrite_a
         
         ! Initialize a matrix temporary
         if (copy_a) then
            allocate (amat(m,n),source=a)
         else
            amat => a
         end if

         ! Decide if U, V eigenvectors
         task_u = eigenvectors_task(present(left))
         task_v = eigenvectors_task(present(right))
         
         if (present(right)) then
                        
            ! For a real matrix, GEEV returns real arrays.
            ! Allocate temporary reals, will be converted to complex vectors at the end.
            allocate (vmat(n,n))
            
            if (size(vmat,2,kind=ilp) < n) then
               err0 = la_state(this,LINALG_VALUE_ERROR, &
                                        'right eigenvector matrix has insufficient size: ', &
                                        shape(vmat),', with n=',n)
            end if
            
         else
            vmat => v_dummy
         end if
            
         if (present(left)) then
            
            ! For a real matrix, GEEV returns real arrays.
            ! Allocate temporary reals, will be converted to complex vectors at the end.
            allocate (umat(n,n))

            if (size(umat,2,kind=ilp) < n) then
               err0 = la_state(this,LINALG_VALUE_ERROR, &
                                        'left eigenvector matrix has insufficient size: ', &
                                        shape(umat),', with n=',n)
            end if
            
         else
            umat => u_dummy
         end if
         
         get_geev: if (err0%ok()) then

             ldu = size(umat,1,kind=ilp)
             ldv = size(vmat,1,kind=ilp)

             ! Compute workspace size
             allocate (lreal(n),limag(n))

             lwork = -1_ilp
            
             call geev(task_u,task_v,n,amat,lda, &
                       lreal,limag, &
                       umat,ldu,vmat,ldv, &
                       work_dummy,lwork,info)
             call handle_geev_info(err0,info,shape(amat))

             ! Compute eigenvalues
             if (info == 0) then

                !> Prepare working storage
                lwork = nint(real(work_dummy(1),kind=sp),kind=ilp)
                allocate (work(lwork))

                !> Compute eigensystem
                call geev(task_u,task_v,n,amat,lda, &
                          lreal,limag, &
                          umat,ldu,vmat,ldv, &
                          work,lwork,info)
                call handle_geev_info(err0,info,shape(amat))

             end if
             
             ! Finalize storage and process output flag
             lambda(:n) = cmplx(lreal(:n),limag(:n),kind=sp)
             
             ! If the j-th and (j+1)-st eigenvalues form a complex conjugate pair,
             ! geev returns reals as:
             ! u(j)   = VL(:,j) + i*VL(:,j+1) and
             ! u(j+1) = VL(:,j) - i*VL(:,j+1).
             ! Convert these to complex numbers here.
             if (present(right)) call assign_real_eigenvectors_sp(n,lambda,vmat,right)
             if (present(left)) call assign_real_eigenvectors_sp(n,lambda,umat,left)
         
         end if get_geev
         
         if (copy_a) deallocate (amat)
         if (present(right)) deallocate (vmat)
         if (present(left)) deallocate (umat)
         call err0%handle(err)

     end subroutine la_eig_standard_s
     
     function la_eigvals_generalized_s(a,b,err) result(lambda)
     !! Return an array of eigenvalues of matrix A.
         !> Input matrix A[m,n]
         real(sp),intent(in),dimension(:,:),target :: a
         !> Generalized problem matrix B[n,n]
         real(sp),intent(inout),dimension(:,:),target :: b
         !> [optional] state return flag. On error if not requested, the code will stop
         type(la_state),intent(out) :: err
         !> Array of eigenvalues
         complex(sp),allocatable :: lambda(:)

         !> Create
         real(sp),pointer,dimension(:,:) :: amat,bmat
         integer(ilp) :: m,n,k

         !> Create an internal pointer so the intent of A won't affect the next call
         amat => a
         bmat => b

         m = size(a,1,kind=ilp)
         n = size(a,2,kind=ilp)
         k = min(m,n)

         !> Allocate return storage
         allocate (lambda(k))

         !> Compute eigenvalues only
         call la_eig_generalized_s(amat,bmat,lambda,err=err)

     end function la_eigvals_generalized_s

     function la_eigvals_noerr_generalized_s(a,b) result(lambda)
     !! Return an array of eigenvalues of matrix A.
         !> Input matrix A[m,n]
         real(sp),intent(in),dimension(:,:),target :: a
         !> Generalized problem matrix B[n,n]
         real(sp),intent(inout),dimension(:,:),target :: b
         !> Array of eigenvalues
         complex(sp),allocatable :: lambda(:)

         !> Create
         real(sp),pointer,dimension(:,:) :: amat,bmat
         integer(ilp) :: m,n,k

         !> Create an internal pointer so the intent of A won't affect the next call
         amat => a
         bmat => b

         m = size(a,1,kind=ilp)
         n = size(a,2,kind=ilp)
         k = min(m,n)

         !> Allocate return storage
         allocate (lambda(k))

         !> Compute eigenvalues only
         call la_eig_generalized_s(amat,bmat,lambda,overwrite_a=.false.)

     end function la_eigvals_noerr_generalized_s

     subroutine la_eig_generalized_s(a,b,lambda,right,left, &
                                                       overwrite_a,overwrite_b,err)
     !! Eigendecomposition of matrix A returning an array `lambda` of eigenvalues,
     !! and optionally right or left eigenvectors.
         !> Input matrix A[m,n]
         real(sp),intent(inout),dimension(:,:),target :: a
         !> Generalized problem matrix B[n,n]
         real(sp),intent(inout),dimension(:,:),target :: b
         !> Array of eigenvalues
         complex(sp),intent(out) :: lambda(:)
         !> [optional] RIGHT eigenvectors of A (as columns)
         complex(sp),optional,intent(out),target :: right(:,:)
         !> [optional] LEFT eigenvectors of A (as columns)
         complex(sp),optional,intent(out),target :: left(:,:)
         !> [optional] Can A data be overwritten and destroyed? (default: no)
         logical(lk),optional,intent(in) :: overwrite_a
         !> [optional] Can B data be overwritten and destroyed? (default: no)
         logical(lk),optional,intent(in) :: overwrite_b
         !> [optional] state return flag. On error if not requested, the code will stop
         type(la_state),optional,intent(out) :: err

         !> Local variables
         type(la_state) :: err0
         integer(ilp) :: m,n,lda,ldu,ldv,info,k,lwork,neig,ldb,nb
         logical(lk) :: copy_a,copy_b
         character :: task_u,task_v
         real(sp),target :: work_dummy(1),u_dummy(1,1),v_dummy(1,1)
         real(sp),allocatable :: work(:)
         real(sp),dimension(:,:),pointer :: amat,umat,vmat,bmat
         real(sp),pointer :: lreal(:),limag(:)
         real(sp),allocatable :: beta(:)
         
         !> Matrix size
         m = size(a,1,kind=ilp)
         n = size(a,2,kind=ilp)
         k = min(m,n)
         neig = size(lambda,kind=ilp)
         lda = m

         if (k <= 0 .or. m /= n) then
            err0 = la_state(this,LINALG_VALUE_ERROR, &
                                          'invalid or matrix size a=', [m,n],', must be nonempty square.')
            call err0%handle(err)
            return
         elseif (neig < k) then
            err0 = la_state(this,LINALG_VALUE_ERROR, &
                                          'eigenvalue array has insufficient size:', &
                                          ' lambda=',neig,', n=',n)
            call err0%handle(err)
            return
         end if
         
         ldb = size(b,1,kind=ilp)
         nb = size(b,2,kind=ilp)
         if (ldb /= n .or. nb /= n) then
            err0 = la_state(this,LINALG_VALUE_ERROR, &
                                          'invalid or matrix size b=', [ldb,nb],', must be same as a=', [m,n])
            call err0%handle(err)
            return
         end if

         ! Can A be overwritten? By default, do not overwrite
         copy_a = .true._lk
         if (present(overwrite_a)) copy_a = .not. overwrite_a
         
         ! Initialize a matrix temporary
         if (copy_a) then
            allocate (amat(m,n),source=a)
         else
            amat => a
         end if

         ! Can B be overwritten? By default, do not overwrite
         copy_b = .true._lk
         if (present(overwrite_b)) copy_b = .not. overwrite_b
         
         ! Initialize a matrix temporary
         if (copy_b) then
            allocate (bmat,source=b)
         else
            bmat => b
         end if
         allocate (beta(n))

         ! Decide if U, V eigenvectors
         task_u = eigenvectors_task(present(left))
         task_v = eigenvectors_task(present(right))
         
         if (present(right)) then
                        
            ! For a real matrix, GEEV returns real arrays.
            ! Allocate temporary reals, will be converted to complex vectors at the end.
            allocate (vmat(n,n))
            
            if (size(vmat,2,kind=ilp) < n) then
               err0 = la_state(this,LINALG_VALUE_ERROR, &
                                        'right eigenvector matrix has insufficient size: ', &
                                        shape(vmat),', with n=',n)
            end if
            
         else
            vmat => v_dummy
         end if
            
         if (present(left)) then
            
            ! For a real matrix, GEEV returns real arrays.
            ! Allocate temporary reals, will be converted to complex vectors at the end.
            allocate (umat(n,n))

            if (size(umat,2,kind=ilp) < n) then
               err0 = la_state(this,LINALG_VALUE_ERROR, &
                                        'left eigenvector matrix has insufficient size: ', &
                                        shape(umat),', with n=',n)
            end if
            
         else
            umat => u_dummy
         end if
         
         get_ggev: if (err0%ok()) then

             ldu = size(umat,1,kind=ilp)
             ldv = size(vmat,1,kind=ilp)

             ! Compute workspace size
             allocate (lreal(n),limag(n))

             lwork = -1_ilp
            
             call ggev(task_u,task_v,n,amat,lda, &
                       bmat,ldb, &
                       lreal,limag, &
                       beta, &
                       umat,ldu,vmat,ldv, &
                       work_dummy,lwork,info)
             call handle_ggev_info(err0,info,shape(amat),shape(bmat))

             ! Compute eigenvalues
             if (info == 0) then

                !> Prepare working storage
                lwork = nint(real(work_dummy(1),kind=sp),kind=ilp)
                allocate (work(lwork))

                !> Compute eigensystem
                call ggev(task_u,task_v,n,amat,lda, &
                          bmat,ldb, &
                          lreal,limag, &
                          beta, &
                          umat,ldu,vmat,ldv, &
                          work,lwork,info)
                call handle_ggev_info(err0,info,shape(amat),shape(bmat))

             end if
             
             ! Finalize storage and process output flag
             lambda(:n) = cmplx(lreal(:n),limag(:n),kind=sp)
             
             ! Scale generalized eigenvalues
             lambda(:n) = scale_general_eig(lambda(:n),beta)
             
             ! If the j-th and (j+1)-st eigenvalues form a complex conjugate pair,
             ! ggev returns reals as:
             ! u(j)   = VL(:,j) + i*VL(:,j+1) and
             ! u(j+1) = VL(:,j) - i*VL(:,j+1).
             ! Convert these to complex numbers here.
             if (present(right)) call assign_real_eigenvectors_sp(n,lambda,vmat,right)
             if (present(left)) call assign_real_eigenvectors_sp(n,lambda,umat,left)
         
         end if get_ggev
         
         if (copy_a) deallocate (amat)
         if (copy_b) deallocate (bmat)
         if (present(right)) deallocate (vmat)
         if (present(left)) deallocate (umat)
         call err0%handle(err)

     end subroutine la_eig_generalized_s
     
     !> Return an array of eigenvalues of real symmetric / complex hermitian A
     function la_eigvalsh_s(a,upper_a,err) result(lambda)
         !> Input matrix A[m,n]
         real(sp),intent(in),target :: a(:,:)
         !> [optional] Should the upper/lower half of A be used? Default: lower
         logical(lk),optional,intent(in) :: upper_a
         !> [optional] state return flag. On error if not requested, the code will stop
         type(la_state),intent(out) :: err
         !> Array of singular values
         real(sp),allocatable :: lambda(:)
         
         real(sp),pointer :: amat(:,:)
         integer(ilp) :: m,n,k

         !> Create an internal pointer so the intent of A won't affect the next call
         amat => a

         m = size(a,1,kind=ilp)
         n = size(a,2,kind=ilp)
         k = min(m,n)

         !> Allocate return storage
         allocate (lambda(k))

         !> Compute eigenvalues only
         call la_eigh_s(amat,lambda,upper_a=upper_a,overwrite_a=.false.,err=err)
         
     end function la_eigvalsh_s
     
     !> Return an array of eigenvalues of real symmetric / complex hermitian A
     function la_eigvalsh_noerr_s(a,upper_a) result(lambda)
         !> Input matrix A[m,n]
         real(sp),intent(in),target :: a(:,:)
         !> [optional] Should the upper/lower half of A be used? Default: lower
         logical(lk),optional,intent(in) :: upper_a
         !> Array of singular values
         real(sp),allocatable :: lambda(:)

         real(sp),pointer :: amat(:,:)
         integer(ilp) :: m,n,k

         !> Create an internal pointer so the intent of A won't affect the next call
         amat => a

         m = size(a,1,kind=ilp)
         n = size(a,2,kind=ilp)
         k = min(m,n)

         !> Allocate return storage
         allocate (lambda(k))

         !> Compute eigenvalues only
         call la_eigh_s(amat,lambda,upper_a=upper_a,overwrite_a=.false.)

     end function la_eigvalsh_noerr_s

     !> Eigendecomposition of a real symmetric or complex Hermitian matrix A returning an array `lambda`
     !> of eigenvalues, and optionally right or left eigenvectors.
     subroutine la_eigh_s(a,lambda,vectors,upper_a,overwrite_a,err)
         !> Input matrix A[m,n]
         real(sp),intent(inout),target :: a(:,:)
         !> Array of eigenvalues
         real(sp),intent(out) :: lambda(:)
         !> The columns of vectors contain the orthonormal eigenvectors of A
         real(sp),optional,intent(out),target :: vectors(:,:)
         !> [optional] Can A data be overwritten and destroyed?
         logical(lk),optional,intent(in) :: overwrite_a
         !> [optional] Should the upper/lower half of A be used? Default: lower
         logical(lk),optional,intent(in) :: upper_a
         !> [optional] state return flag. On error if not requested, the code will stop
         type(la_state),optional,intent(out) :: err

         !> Local variables
         type(la_state) :: err0
         integer(ilp) :: m,n,lda,info,k,lwork,neig
         logical(lk) :: copy_a
         character :: triangle,task
         real(sp),target :: work_dummy(1)
         real(sp),allocatable :: work(:)
         real(sp),allocatable :: rwork(:)
         real(sp),pointer :: amat(:,:)

         !> Matrix size
         m = size(a,1,kind=ilp)
         n = size(a,2,kind=ilp)
         k = min(m,n)
         neig = size(lambda,kind=ilp)

         if (.not. (k > 0 .and. m == n)) then
            err0 = la_state(this,LINALG_VALUE_ERROR,'invalid or matrix size a=', [m,n], &
                                                        ', must be square.')
            call err0%handle(err)
            return
         end if

         if (.not. neig >= k) then
            err0 = la_state(this,LINALG_VALUE_ERROR,'eigenvalue array has insufficient size:', &
                                                        ' lambda=',neig,' must be >= n=',n)
            call err0%handle(err)
            return
         end if
        
         ! Check if input A can be overwritten
         if (present(vectors)) then
            ! No need to copy A anyways
            copy_a = .false.
         elseif (present(overwrite_a)) then
            copy_a = .not. overwrite_a
         else
            copy_a = .true._lk
         end if
         
         ! Should we use the upper or lower half of the matrix?
         triangle = symmetric_triangle_task(upper_a)
         
         ! Request for eigenvectors
         task = eigenvectors_task(present(vectors))
         
         if (present(vectors)) then
            
            ! Check size
            if (any(shape(vectors,kind=ilp) < n)) then
               err0 = la_state(this,LINALG_VALUE_ERROR, &
                                        'eigenvector matrix has insufficient size: ', &
                                        shape(vectors),', with n=',n)
               call err0%handle(err)
               return
            end if
            
            ! The input matrix will be overwritten by the vectors.
            ! So, use this one as storage for syev/heev
            amat => vectors
            
            ! Copy data in
            amat(:n,:n) = a(:n,:n)
                        
         elseif (copy_a) then
            ! Initialize a matrix temporary
            allocate (amat(m,n),source=a)
         else
            ! Overwrite A
            amat => a
         end if

         lda = size(amat,1,kind=ilp)

         ! Request workspace size
         lwork = -1_ilp
         call syev(task,triangle,n,amat,lda,lambda,work_dummy,lwork,info)
         call heev_info(err0,info,m,n)

         ! Compute eigenvalues
         if (info == 0) then

            !> Prepare working storage
            lwork = nint(real(work_dummy(1),kind=sp),kind=ilp)
            allocate (work(lwork))

            !> Compute eigensystem
            call syev(task,triangle,n,amat,lda,lambda,work,lwork,info)
            call heev_info(err0,info,m,n)

         end if
         
         ! Finalize storage and process output flag
         if (copy_a) deallocate (amat)
         call err0%handle(err)

     end subroutine la_eigh_s
     
     function la_eigvals_standard_d(a,err) result(lambda)
     !! Return an array of eigenvalues of matrix A.
         !> Input matrix A[m,n]
         real(dp),intent(in),dimension(:,:),target :: a
         !> [optional] state return flag. On error if not requested, the code will stop
         type(la_state),intent(out) :: err
         !> Array of eigenvalues
         complex(dp),allocatable :: lambda(:)

         !> Create
         real(dp),pointer,dimension(:,:) :: amat
         integer(ilp) :: m,n,k

         !> Create an internal pointer so the intent of A won't affect the next call
         amat => a
         
         m = size(a,1,kind=ilp)
         n = size(a,2,kind=ilp)
         k = min(m,n)

         !> Allocate return storage
         allocate (lambda(k))

         !> Compute eigenvalues only
         call la_eig_standard_d(amat,lambda,err=err)

     end function la_eigvals_standard_d

     function la_eigvals_noerr_standard_d(a) result(lambda)
     !! Return an array of eigenvalues of matrix A.
         !> Input matrix A[m,n]
         real(dp),intent(in),dimension(:,:),target :: a
         !> Array of eigenvalues
         complex(dp),allocatable :: lambda(:)

         !> Create
         real(dp),pointer,dimension(:,:) :: amat
         integer(ilp) :: m,n,k

         !> Create an internal pointer so the intent of A won't affect the next call
         amat => a
         
         m = size(a,1,kind=ilp)
         n = size(a,2,kind=ilp)
         k = min(m,n)

         !> Allocate return storage
         allocate (lambda(k))

         !> Compute eigenvalues only
         call la_eig_standard_d(amat,lambda,overwrite_a=.false.)

     end function la_eigvals_noerr_standard_d

     subroutine la_eig_standard_d(a,lambda,right,left, &
                                                       overwrite_a,err)
     !! Eigendecomposition of matrix A returning an array `lambda` of eigenvalues,
     !! and optionally right or left eigenvectors.
         !> Input matrix A[m,n]
         real(dp),intent(inout),dimension(:,:),target :: a
         !> Array of eigenvalues
         complex(dp),intent(out) :: lambda(:)
         !> [optional] RIGHT eigenvectors of A (as columns)
         complex(dp),optional,intent(out),target :: right(:,:)
         !> [optional] LEFT eigenvectors of A (as columns)
         complex(dp),optional,intent(out),target :: left(:,:)
         !> [optional] Can A data be overwritten and destroyed? (default: no)
         logical(lk),optional,intent(in) :: overwrite_a
         !> [optional] state return flag. On error if not requested, the code will stop
         type(la_state),optional,intent(out) :: err

         !> Local variables
         type(la_state) :: err0
         integer(ilp) :: m,n,lda,ldu,ldv,info,k,lwork,neig
         logical(lk) :: copy_a
         character :: task_u,task_v
         real(dp),target :: work_dummy(1),u_dummy(1,1),v_dummy(1,1)
         real(dp),allocatable :: work(:)
         real(dp),dimension(:,:),pointer :: amat,umat,vmat
         real(dp),pointer :: lreal(:),limag(:)
         
         !> Matrix size
         m = size(a,1,kind=ilp)
         n = size(a,2,kind=ilp)
         k = min(m,n)
         neig = size(lambda,kind=ilp)
         lda = m

         if (k <= 0 .or. m /= n) then
            err0 = la_state(this,LINALG_VALUE_ERROR, &
                                          'invalid or matrix size a=', [m,n],', must be nonempty square.')
            call err0%handle(err)
            return
         elseif (neig < k) then
            err0 = la_state(this,LINALG_VALUE_ERROR, &
                                          'eigenvalue array has insufficient size:', &
                                          ' lambda=',neig,', n=',n)
            call err0%handle(err)
            return
         end if
         
         ! Can A be overwritten? By default, do not overwrite
         copy_a = .true._lk
         if (present(overwrite_a)) copy_a = .not. overwrite_a
         
         ! Initialize a matrix temporary
         if (copy_a) then
            allocate (amat(m,n),source=a)
         else
            amat => a
         end if

         ! Decide if U, V eigenvectors
         task_u = eigenvectors_task(present(left))
         task_v = eigenvectors_task(present(right))
         
         if (present(right)) then
                        
            ! For a real matrix, GEEV returns real arrays.
            ! Allocate temporary reals, will be converted to complex vectors at the end.
            allocate (vmat(n,n))
            
            if (size(vmat,2,kind=ilp) < n) then
               err0 = la_state(this,LINALG_VALUE_ERROR, &
                                        'right eigenvector matrix has insufficient size: ', &
                                        shape(vmat),', with n=',n)
            end if
            
         else
            vmat => v_dummy
         end if
            
         if (present(left)) then
            
            ! For a real matrix, GEEV returns real arrays.
            ! Allocate temporary reals, will be converted to complex vectors at the end.
            allocate (umat(n,n))

            if (size(umat,2,kind=ilp) < n) then
               err0 = la_state(this,LINALG_VALUE_ERROR, &
                                        'left eigenvector matrix has insufficient size: ', &
                                        shape(umat),', with n=',n)
            end if
            
         else
            umat => u_dummy
         end if
         
         get_geev: if (err0%ok()) then

             ldu = size(umat,1,kind=ilp)
             ldv = size(vmat,1,kind=ilp)

             ! Compute workspace size
             allocate (lreal(n),limag(n))

             lwork = -1_ilp
            
             call geev(task_u,task_v,n,amat,lda, &
                       lreal,limag, &
                       umat,ldu,vmat,ldv, &
                       work_dummy,lwork,info)
             call handle_geev_info(err0,info,shape(amat))

             ! Compute eigenvalues
             if (info == 0) then

                !> Prepare working storage
                lwork = nint(real(work_dummy(1),kind=dp),kind=ilp)
                allocate (work(lwork))

                !> Compute eigensystem
                call geev(task_u,task_v,n,amat,lda, &
                          lreal,limag, &
                          umat,ldu,vmat,ldv, &
                          work,lwork,info)
                call handle_geev_info(err0,info,shape(amat))

             end if
             
             ! Finalize storage and process output flag
             lambda(:n) = cmplx(lreal(:n),limag(:n),kind=dp)
             
             ! If the j-th and (j+1)-st eigenvalues form a complex conjugate pair,
             ! geev returns reals as:
             ! u(j)   = VL(:,j) + i*VL(:,j+1) and
             ! u(j+1) = VL(:,j) - i*VL(:,j+1).
             ! Convert these to complex numbers here.
             if (present(right)) call assign_real_eigenvectors_dp(n,lambda,vmat,right)
             if (present(left)) call assign_real_eigenvectors_dp(n,lambda,umat,left)
         
         end if get_geev
         
         if (copy_a) deallocate (amat)
         if (present(right)) deallocate (vmat)
         if (present(left)) deallocate (umat)
         call err0%handle(err)

     end subroutine la_eig_standard_d
     
     function la_eigvals_generalized_d(a,b,err) result(lambda)
     !! Return an array of eigenvalues of matrix A.
         !> Input matrix A[m,n]
         real(dp),intent(in),dimension(:,:),target :: a
         !> Generalized problem matrix B[n,n]
         real(dp),intent(inout),dimension(:,:),target :: b
         !> [optional] state return flag. On error if not requested, the code will stop
         type(la_state),intent(out) :: err
         !> Array of eigenvalues
         complex(dp),allocatable :: lambda(:)

         !> Create
         real(dp),pointer,dimension(:,:) :: amat,bmat
         integer(ilp) :: m,n,k

         !> Create an internal pointer so the intent of A won't affect the next call
         amat => a
         bmat => b

         m = size(a,1,kind=ilp)
         n = size(a,2,kind=ilp)
         k = min(m,n)

         !> Allocate return storage
         allocate (lambda(k))

         !> Compute eigenvalues only
         call la_eig_generalized_d(amat,bmat,lambda,err=err)

     end function la_eigvals_generalized_d

     function la_eigvals_noerr_generalized_d(a,b) result(lambda)
     !! Return an array of eigenvalues of matrix A.
         !> Input matrix A[m,n]
         real(dp),intent(in),dimension(:,:),target :: a
         !> Generalized problem matrix B[n,n]
         real(dp),intent(inout),dimension(:,:),target :: b
         !> Array of eigenvalues
         complex(dp),allocatable :: lambda(:)

         !> Create
         real(dp),pointer,dimension(:,:) :: amat,bmat
         integer(ilp) :: m,n,k

         !> Create an internal pointer so the intent of A won't affect the next call
         amat => a
         bmat => b

         m = size(a,1,kind=ilp)
         n = size(a,2,kind=ilp)
         k = min(m,n)

         !> Allocate return storage
         allocate (lambda(k))

         !> Compute eigenvalues only
         call la_eig_generalized_d(amat,bmat,lambda,overwrite_a=.false.)

     end function la_eigvals_noerr_generalized_d

     subroutine la_eig_generalized_d(a,b,lambda,right,left, &
                                                       overwrite_a,overwrite_b,err)
     !! Eigendecomposition of matrix A returning an array `lambda` of eigenvalues,
     !! and optionally right or left eigenvectors.
         !> Input matrix A[m,n]
         real(dp),intent(inout),dimension(:,:),target :: a
         !> Generalized problem matrix B[n,n]
         real(dp),intent(inout),dimension(:,:),target :: b
         !> Array of eigenvalues
         complex(dp),intent(out) :: lambda(:)
         !> [optional] RIGHT eigenvectors of A (as columns)
         complex(dp),optional,intent(out),target :: right(:,:)
         !> [optional] LEFT eigenvectors of A (as columns)
         complex(dp),optional,intent(out),target :: left(:,:)
         !> [optional] Can A data be overwritten and destroyed? (default: no)
         logical(lk),optional,intent(in) :: overwrite_a
         !> [optional] Can B data be overwritten and destroyed? (default: no)
         logical(lk),optional,intent(in) :: overwrite_b
         !> [optional] state return flag. On error if not requested, the code will stop
         type(la_state),optional,intent(out) :: err

         !> Local variables
         type(la_state) :: err0
         integer(ilp) :: m,n,lda,ldu,ldv,info,k,lwork,neig,ldb,nb
         logical(lk) :: copy_a,copy_b
         character :: task_u,task_v
         real(dp),target :: work_dummy(1),u_dummy(1,1),v_dummy(1,1)
         real(dp),allocatable :: work(:)
         real(dp),dimension(:,:),pointer :: amat,umat,vmat,bmat
         real(dp),pointer :: lreal(:),limag(:)
         real(dp),allocatable :: beta(:)
         
         !> Matrix size
         m = size(a,1,kind=ilp)
         n = size(a,2,kind=ilp)
         k = min(m,n)
         neig = size(lambda,kind=ilp)
         lda = m

         if (k <= 0 .or. m /= n) then
            err0 = la_state(this,LINALG_VALUE_ERROR, &
                                          'invalid or matrix size a=', [m,n],', must be nonempty square.')
            call err0%handle(err)
            return
         elseif (neig < k) then
            err0 = la_state(this,LINALG_VALUE_ERROR, &
                                          'eigenvalue array has insufficient size:', &
                                          ' lambda=',neig,', n=',n)
            call err0%handle(err)
            return
         end if
         
         ldb = size(b,1,kind=ilp)
         nb = size(b,2,kind=ilp)
         if (ldb /= n .or. nb /= n) then
            err0 = la_state(this,LINALG_VALUE_ERROR, &
                                          'invalid or matrix size b=', [ldb,nb],', must be same as a=', [m,n])
            call err0%handle(err)
            return
         end if

         ! Can A be overwritten? By default, do not overwrite
         copy_a = .true._lk
         if (present(overwrite_a)) copy_a = .not. overwrite_a
         
         ! Initialize a matrix temporary
         if (copy_a) then
            allocate (amat(m,n),source=a)
         else
            amat => a
         end if

         ! Can B be overwritten? By default, do not overwrite
         copy_b = .true._lk
         if (present(overwrite_b)) copy_b = .not. overwrite_b
         
         ! Initialize a matrix temporary
         if (copy_b) then
            allocate (bmat,source=b)
         else
            bmat => b
         end if
         allocate (beta(n))

         ! Decide if U, V eigenvectors
         task_u = eigenvectors_task(present(left))
         task_v = eigenvectors_task(present(right))
         
         if (present(right)) then
                        
            ! For a real matrix, GEEV returns real arrays.
            ! Allocate temporary reals, will be converted to complex vectors at the end.
            allocate (vmat(n,n))
            
            if (size(vmat,2,kind=ilp) < n) then
               err0 = la_state(this,LINALG_VALUE_ERROR, &
                                        'right eigenvector matrix has insufficient size: ', &
                                        shape(vmat),', with n=',n)
            end if
            
         else
            vmat => v_dummy
         end if
            
         if (present(left)) then
            
            ! For a real matrix, GEEV returns real arrays.
            ! Allocate temporary reals, will be converted to complex vectors at the end.
            allocate (umat(n,n))

            if (size(umat,2,kind=ilp) < n) then
               err0 = la_state(this,LINALG_VALUE_ERROR, &
                                        'left eigenvector matrix has insufficient size: ', &
                                        shape(umat),', with n=',n)
            end if
            
         else
            umat => u_dummy
         end if
         
         get_ggev: if (err0%ok()) then

             ldu = size(umat,1,kind=ilp)
             ldv = size(vmat,1,kind=ilp)

             ! Compute workspace size
             allocate (lreal(n),limag(n))

             lwork = -1_ilp
            
             call ggev(task_u,task_v,n,amat,lda, &
                       bmat,ldb, &
                       lreal,limag, &
                       beta, &
                       umat,ldu,vmat,ldv, &
                       work_dummy,lwork,info)
             call handle_ggev_info(err0,info,shape(amat),shape(bmat))

             ! Compute eigenvalues
             if (info == 0) then

                !> Prepare working storage
                lwork = nint(real(work_dummy(1),kind=dp),kind=ilp)
                allocate (work(lwork))

                !> Compute eigensystem
                call ggev(task_u,task_v,n,amat,lda, &
                          bmat,ldb, &
                          lreal,limag, &
                          beta, &
                          umat,ldu,vmat,ldv, &
                          work,lwork,info)
                call handle_ggev_info(err0,info,shape(amat),shape(bmat))

             end if
             
             ! Finalize storage and process output flag
             lambda(:n) = cmplx(lreal(:n),limag(:n),kind=dp)
             
             ! Scale generalized eigenvalues
             lambda(:n) = scale_general_eig(lambda(:n),beta)
             
             ! If the j-th and (j+1)-st eigenvalues form a complex conjugate pair,
             ! ggev returns reals as:
             ! u(j)   = VL(:,j) + i*VL(:,j+1) and
             ! u(j+1) = VL(:,j) - i*VL(:,j+1).
             ! Convert these to complex numbers here.
             if (present(right)) call assign_real_eigenvectors_dp(n,lambda,vmat,right)
             if (present(left)) call assign_real_eigenvectors_dp(n,lambda,umat,left)
         
         end if get_ggev
         
         if (copy_a) deallocate (amat)
         if (copy_b) deallocate (bmat)
         if (present(right)) deallocate (vmat)
         if (present(left)) deallocate (umat)
         call err0%handle(err)

     end subroutine la_eig_generalized_d
     
     !> Return an array of eigenvalues of real symmetric / complex hermitian A
     function la_eigvalsh_d(a,upper_a,err) result(lambda)
         !> Input matrix A[m,n]
         real(dp),intent(in),target :: a(:,:)
         !> [optional] Should the upper/lower half of A be used? Default: lower
         logical(lk),optional,intent(in) :: upper_a
         !> [optional] state return flag. On error if not requested, the code will stop
         type(la_state),intent(out) :: err
         !> Array of singular values
         real(dp),allocatable :: lambda(:)
         
         real(dp),pointer :: amat(:,:)
         integer(ilp) :: m,n,k

         !> Create an internal pointer so the intent of A won't affect the next call
         amat => a

         m = size(a,1,kind=ilp)
         n = size(a,2,kind=ilp)
         k = min(m,n)

         !> Allocate return storage
         allocate (lambda(k))

         !> Compute eigenvalues only
         call la_eigh_d(amat,lambda,upper_a=upper_a,overwrite_a=.false.,err=err)
         
     end function la_eigvalsh_d
     
     !> Return an array of eigenvalues of real symmetric / complex hermitian A
     function la_eigvalsh_noerr_d(a,upper_a) result(lambda)
         !> Input matrix A[m,n]
         real(dp),intent(in),target :: a(:,:)
         !> [optional] Should the upper/lower half of A be used? Default: lower
         logical(lk),optional,intent(in) :: upper_a
         !> Array of singular values
         real(dp),allocatable :: lambda(:)

         real(dp),pointer :: amat(:,:)
         integer(ilp) :: m,n,k

         !> Create an internal pointer so the intent of A won't affect the next call
         amat => a

         m = size(a,1,kind=ilp)
         n = size(a,2,kind=ilp)
         k = min(m,n)

         !> Allocate return storage
         allocate (lambda(k))

         !> Compute eigenvalues only
         call la_eigh_d(amat,lambda,upper_a=upper_a,overwrite_a=.false.)

     end function la_eigvalsh_noerr_d

     !> Eigendecomposition of a real symmetric or complex Hermitian matrix A returning an array `lambda`
     !> of eigenvalues, and optionally right or left eigenvectors.
     subroutine la_eigh_d(a,lambda,vectors,upper_a,overwrite_a,err)
         !> Input matrix A[m,n]
         real(dp),intent(inout),target :: a(:,:)
         !> Array of eigenvalues
         real(dp),intent(out) :: lambda(:)
         !> The columns of vectors contain the orthonormal eigenvectors of A
         real(dp),optional,intent(out),target :: vectors(:,:)
         !> [optional] Can A data be overwritten and destroyed?
         logical(lk),optional,intent(in) :: overwrite_a
         !> [optional] Should the upper/lower half of A be used? Default: lower
         logical(lk),optional,intent(in) :: upper_a
         !> [optional] state return flag. On error if not requested, the code will stop
         type(la_state),optional,intent(out) :: err

         !> Local variables
         type(la_state) :: err0
         integer(ilp) :: m,n,lda,info,k,lwork,neig
         logical(lk) :: copy_a
         character :: triangle,task
         real(dp),target :: work_dummy(1)
         real(dp),allocatable :: work(:)
         real(dp),allocatable :: rwork(:)
         real(dp),pointer :: amat(:,:)

         !> Matrix size
         m = size(a,1,kind=ilp)
         n = size(a,2,kind=ilp)
         k = min(m,n)
         neig = size(lambda,kind=ilp)

         if (.not. (k > 0 .and. m == n)) then
            err0 = la_state(this,LINALG_VALUE_ERROR,'invalid or matrix size a=', [m,n], &
                                                        ', must be square.')
            call err0%handle(err)
            return
         end if

         if (.not. neig >= k) then
            err0 = la_state(this,LINALG_VALUE_ERROR,'eigenvalue array has insufficient size:', &
                                                        ' lambda=',neig,' must be >= n=',n)
            call err0%handle(err)
            return
         end if
        
         ! Check if input A can be overwritten
         if (present(vectors)) then
            ! No need to copy A anyways
            copy_a = .false.
         elseif (present(overwrite_a)) then
            copy_a = .not. overwrite_a
         else
            copy_a = .true._lk
         end if
         
         ! Should we use the upper or lower half of the matrix?
         triangle = symmetric_triangle_task(upper_a)
         
         ! Request for eigenvectors
         task = eigenvectors_task(present(vectors))
         
         if (present(vectors)) then
            
            ! Check size
            if (any(shape(vectors,kind=ilp) < n)) then
               err0 = la_state(this,LINALG_VALUE_ERROR, &
                                        'eigenvector matrix has insufficient size: ', &
                                        shape(vectors),', with n=',n)
               call err0%handle(err)
               return
            end if
            
            ! The input matrix will be overwritten by the vectors.
            ! So, use this one as storage for syev/heev
            amat => vectors
            
            ! Copy data in
            amat(:n,:n) = a(:n,:n)
                        
         elseif (copy_a) then
            ! Initialize a matrix temporary
            allocate (amat(m,n),source=a)
         else
            ! Overwrite A
            amat => a
         end if

         lda = size(amat,1,kind=ilp)

         ! Request workspace size
         lwork = -1_ilp
         call syev(task,triangle,n,amat,lda,lambda,work_dummy,lwork,info)
         call heev_info(err0,info,m,n)

         ! Compute eigenvalues
         if (info == 0) then

            !> Prepare working storage
            lwork = nint(real(work_dummy(1),kind=dp),kind=ilp)
            allocate (work(lwork))

            !> Compute eigensystem
            call syev(task,triangle,n,amat,lda,lambda,work,lwork,info)
            call heev_info(err0,info,m,n)

         end if
         
         ! Finalize storage and process output flag
         if (copy_a) deallocate (amat)
         call err0%handle(err)

     end subroutine la_eigh_d
     
     function la_eigvals_standard_q(a,err) result(lambda)
     !! Return an array of eigenvalues of matrix A.
         !> Input matrix A[m,n]
         real(qp),intent(in),dimension(:,:),target :: a
         !> [optional] state return flag. On error if not requested, the code will stop
         type(la_state),intent(out) :: err
         !> Array of eigenvalues
         complex(qp),allocatable :: lambda(:)

         !> Create
         real(qp),pointer,dimension(:,:) :: amat
         integer(ilp) :: m,n,k

         !> Create an internal pointer so the intent of A won't affect the next call
         amat => a
         
         m = size(a,1,kind=ilp)
         n = size(a,2,kind=ilp)
         k = min(m,n)

         !> Allocate return storage
         allocate (lambda(k))

         !> Compute eigenvalues only
         call la_eig_standard_q(amat,lambda,err=err)

     end function la_eigvals_standard_q

     function la_eigvals_noerr_standard_q(a) result(lambda)
     !! Return an array of eigenvalues of matrix A.
         !> Input matrix A[m,n]
         real(qp),intent(in),dimension(:,:),target :: a
         !> Array of eigenvalues
         complex(qp),allocatable :: lambda(:)

         !> Create
         real(qp),pointer,dimension(:,:) :: amat
         integer(ilp) :: m,n,k

         !> Create an internal pointer so the intent of A won't affect the next call
         amat => a
         
         m = size(a,1,kind=ilp)
         n = size(a,2,kind=ilp)
         k = min(m,n)

         !> Allocate return storage
         allocate (lambda(k))

         !> Compute eigenvalues only
         call la_eig_standard_q(amat,lambda,overwrite_a=.false.)

     end function la_eigvals_noerr_standard_q

     subroutine la_eig_standard_q(a,lambda,right,left, &
                                                       overwrite_a,err)
     !! Eigendecomposition of matrix A returning an array `lambda` of eigenvalues,
     !! and optionally right or left eigenvectors.
         !> Input matrix A[m,n]
         real(qp),intent(inout),dimension(:,:),target :: a
         !> Array of eigenvalues
         complex(qp),intent(out) :: lambda(:)
         !> [optional] RIGHT eigenvectors of A (as columns)
         complex(qp),optional,intent(out),target :: right(:,:)
         !> [optional] LEFT eigenvectors of A (as columns)
         complex(qp),optional,intent(out),target :: left(:,:)
         !> [optional] Can A data be overwritten and destroyed? (default: no)
         logical(lk),optional,intent(in) :: overwrite_a
         !> [optional] state return flag. On error if not requested, the code will stop
         type(la_state),optional,intent(out) :: err

         !> Local variables
         type(la_state) :: err0
         integer(ilp) :: m,n,lda,ldu,ldv,info,k,lwork,neig
         logical(lk) :: copy_a
         character :: task_u,task_v
         real(qp),target :: work_dummy(1),u_dummy(1,1),v_dummy(1,1)
         real(qp),allocatable :: work(:)
         real(qp),dimension(:,:),pointer :: amat,umat,vmat
         real(qp),pointer :: lreal(:),limag(:)
         
         !> Matrix size
         m = size(a,1,kind=ilp)
         n = size(a,2,kind=ilp)
         k = min(m,n)
         neig = size(lambda,kind=ilp)
         lda = m

         if (k <= 0 .or. m /= n) then
            err0 = la_state(this,LINALG_VALUE_ERROR, &
                                          'invalid or matrix size a=', [m,n],', must be nonempty square.')
            call err0%handle(err)
            return
         elseif (neig < k) then
            err0 = la_state(this,LINALG_VALUE_ERROR, &
                                          'eigenvalue array has insufficient size:', &
                                          ' lambda=',neig,', n=',n)
            call err0%handle(err)
            return
         end if
         
         ! Can A be overwritten? By default, do not overwrite
         copy_a = .true._lk
         if (present(overwrite_a)) copy_a = .not. overwrite_a
         
         ! Initialize a matrix temporary
         if (copy_a) then
            allocate (amat(m,n),source=a)
         else
            amat => a
         end if

         ! Decide if U, V eigenvectors
         task_u = eigenvectors_task(present(left))
         task_v = eigenvectors_task(present(right))
         
         if (present(right)) then
                        
            ! For a real matrix, GEEV returns real arrays.
            ! Allocate temporary reals, will be converted to complex vectors at the end.
            allocate (vmat(n,n))
            
            if (size(vmat,2,kind=ilp) < n) then
               err0 = la_state(this,LINALG_VALUE_ERROR, &
                                        'right eigenvector matrix has insufficient size: ', &
                                        shape(vmat),', with n=',n)
            end if
            
         else
            vmat => v_dummy
         end if
            
         if (present(left)) then
            
            ! For a real matrix, GEEV returns real arrays.
            ! Allocate temporary reals, will be converted to complex vectors at the end.
            allocate (umat(n,n))

            if (size(umat,2,kind=ilp) < n) then
               err0 = la_state(this,LINALG_VALUE_ERROR, &
                                        'left eigenvector matrix has insufficient size: ', &
                                        shape(umat),', with n=',n)
            end if
            
         else
            umat => u_dummy
         end if
         
         get_geev: if (err0%ok()) then

             ldu = size(umat,1,kind=ilp)
             ldv = size(vmat,1,kind=ilp)

             ! Compute workspace size
             allocate (lreal(n),limag(n))

             lwork = -1_ilp
            
             call geev(task_u,task_v,n,amat,lda, &
                       lreal,limag, &
                       umat,ldu,vmat,ldv, &
                       work_dummy,lwork,info)
             call handle_geev_info(err0,info,shape(amat))

             ! Compute eigenvalues
             if (info == 0) then

                !> Prepare working storage
                lwork = nint(real(work_dummy(1),kind=qp),kind=ilp)
                allocate (work(lwork))

                !> Compute eigensystem
                call geev(task_u,task_v,n,amat,lda, &
                          lreal,limag, &
                          umat,ldu,vmat,ldv, &
                          work,lwork,info)
                call handle_geev_info(err0,info,shape(amat))

             end if
             
             ! Finalize storage and process output flag
             lambda(:n) = cmplx(lreal(:n),limag(:n),kind=qp)
             
             ! If the j-th and (j+1)-st eigenvalues form a complex conjugate pair,
             ! geev returns reals as:
             ! u(j)   = VL(:,j) + i*VL(:,j+1) and
             ! u(j+1) = VL(:,j) - i*VL(:,j+1).
             ! Convert these to complex numbers here.
             if (present(right)) call assign_real_eigenvectors_qp(n,lambda,vmat,right)
             if (present(left)) call assign_real_eigenvectors_qp(n,lambda,umat,left)
         
         end if get_geev
         
         if (copy_a) deallocate (amat)
         if (present(right)) deallocate (vmat)
         if (present(left)) deallocate (umat)
         call err0%handle(err)

     end subroutine la_eig_standard_q
     
     function la_eigvals_generalized_q(a,b,err) result(lambda)
     !! Return an array of eigenvalues of matrix A.
         !> Input matrix A[m,n]
         real(qp),intent(in),dimension(:,:),target :: a
         !> Generalized problem matrix B[n,n]
         real(qp),intent(inout),dimension(:,:),target :: b
         !> [optional] state return flag. On error if not requested, the code will stop
         type(la_state),intent(out) :: err
         !> Array of eigenvalues
         complex(qp),allocatable :: lambda(:)

         !> Create
         real(qp),pointer,dimension(:,:) :: amat,bmat
         integer(ilp) :: m,n,k

         !> Create an internal pointer so the intent of A won't affect the next call
         amat => a
         bmat => b

         m = size(a,1,kind=ilp)
         n = size(a,2,kind=ilp)
         k = min(m,n)

         !> Allocate return storage
         allocate (lambda(k))

         !> Compute eigenvalues only
         call la_eig_generalized_q(amat,bmat,lambda,err=err)

     end function la_eigvals_generalized_q

     function la_eigvals_noerr_generalized_q(a,b) result(lambda)
     !! Return an array of eigenvalues of matrix A.
         !> Input matrix A[m,n]
         real(qp),intent(in),dimension(:,:),target :: a
         !> Generalized problem matrix B[n,n]
         real(qp),intent(inout),dimension(:,:),target :: b
         !> Array of eigenvalues
         complex(qp),allocatable :: lambda(:)

         !> Create
         real(qp),pointer,dimension(:,:) :: amat,bmat
         integer(ilp) :: m,n,k

         !> Create an internal pointer so the intent of A won't affect the next call
         amat => a
         bmat => b

         m = size(a,1,kind=ilp)
         n = size(a,2,kind=ilp)
         k = min(m,n)

         !> Allocate return storage
         allocate (lambda(k))

         !> Compute eigenvalues only
         call la_eig_generalized_q(amat,bmat,lambda,overwrite_a=.false.)

     end function la_eigvals_noerr_generalized_q

     subroutine la_eig_generalized_q(a,b,lambda,right,left, &
                                                       overwrite_a,overwrite_b,err)
     !! Eigendecomposition of matrix A returning an array `lambda` of eigenvalues,
     !! and optionally right or left eigenvectors.
         !> Input matrix A[m,n]
         real(qp),intent(inout),dimension(:,:),target :: a
         !> Generalized problem matrix B[n,n]
         real(qp),intent(inout),dimension(:,:),target :: b
         !> Array of eigenvalues
         complex(qp),intent(out) :: lambda(:)
         !> [optional] RIGHT eigenvectors of A (as columns)
         complex(qp),optional,intent(out),target :: right(:,:)
         !> [optional] LEFT eigenvectors of A (as columns)
         complex(qp),optional,intent(out),target :: left(:,:)
         !> [optional] Can A data be overwritten and destroyed? (default: no)
         logical(lk),optional,intent(in) :: overwrite_a
         !> [optional] Can B data be overwritten and destroyed? (default: no)
         logical(lk),optional,intent(in) :: overwrite_b
         !> [optional] state return flag. On error if not requested, the code will stop
         type(la_state),optional,intent(out) :: err

         !> Local variables
         type(la_state) :: err0
         integer(ilp) :: m,n,lda,ldu,ldv,info,k,lwork,neig,ldb,nb
         logical(lk) :: copy_a,copy_b
         character :: task_u,task_v
         real(qp),target :: work_dummy(1),u_dummy(1,1),v_dummy(1,1)
         real(qp),allocatable :: work(:)
         real(qp),dimension(:,:),pointer :: amat,umat,vmat,bmat
         real(qp),pointer :: lreal(:),limag(:)
         real(qp),allocatable :: beta(:)
         
         !> Matrix size
         m = size(a,1,kind=ilp)
         n = size(a,2,kind=ilp)
         k = min(m,n)
         neig = size(lambda,kind=ilp)
         lda = m

         if (k <= 0 .or. m /= n) then
            err0 = la_state(this,LINALG_VALUE_ERROR, &
                                          'invalid or matrix size a=', [m,n],', must be nonempty square.')
            call err0%handle(err)
            return
         elseif (neig < k) then
            err0 = la_state(this,LINALG_VALUE_ERROR, &
                                          'eigenvalue array has insufficient size:', &
                                          ' lambda=',neig,', n=',n)
            call err0%handle(err)
            return
         end if
         
         ldb = size(b,1,kind=ilp)
         nb = size(b,2,kind=ilp)
         if (ldb /= n .or. nb /= n) then
            err0 = la_state(this,LINALG_VALUE_ERROR, &
                                          'invalid or matrix size b=', [ldb,nb],', must be same as a=', [m,n])
            call err0%handle(err)
            return
         end if

         ! Can A be overwritten? By default, do not overwrite
         copy_a = .true._lk
         if (present(overwrite_a)) copy_a = .not. overwrite_a
         
         ! Initialize a matrix temporary
         if (copy_a) then
            allocate (amat(m,n),source=a)
         else
            amat => a
         end if

         ! Can B be overwritten? By default, do not overwrite
         copy_b = .true._lk
         if (present(overwrite_b)) copy_b = .not. overwrite_b
         
         ! Initialize a matrix temporary
         if (copy_b) then
            allocate (bmat,source=b)
         else
            bmat => b
         end if
         allocate (beta(n))

         ! Decide if U, V eigenvectors
         task_u = eigenvectors_task(present(left))
         task_v = eigenvectors_task(present(right))
         
         if (present(right)) then
                        
            ! For a real matrix, GEEV returns real arrays.
            ! Allocate temporary reals, will be converted to complex vectors at the end.
            allocate (vmat(n,n))
            
            if (size(vmat,2,kind=ilp) < n) then
               err0 = la_state(this,LINALG_VALUE_ERROR, &
                                        'right eigenvector matrix has insufficient size: ', &
                                        shape(vmat),', with n=',n)
            end if
            
         else
            vmat => v_dummy
         end if
            
         if (present(left)) then
            
            ! For a real matrix, GEEV returns real arrays.
            ! Allocate temporary reals, will be converted to complex vectors at the end.
            allocate (umat(n,n))

            if (size(umat,2,kind=ilp) < n) then
               err0 = la_state(this,LINALG_VALUE_ERROR, &
                                        'left eigenvector matrix has insufficient size: ', &
                                        shape(umat),', with n=',n)
            end if
            
         else
            umat => u_dummy
         end if
         
         get_ggev: if (err0%ok()) then

             ldu = size(umat,1,kind=ilp)
             ldv = size(vmat,1,kind=ilp)

             ! Compute workspace size
             allocate (lreal(n),limag(n))

             lwork = -1_ilp
            
             call ggev(task_u,task_v,n,amat,lda, &
                       bmat,ldb, &
                       lreal,limag, &
                       beta, &
                       umat,ldu,vmat,ldv, &
                       work_dummy,lwork,info)
             call handle_ggev_info(err0,info,shape(amat),shape(bmat))

             ! Compute eigenvalues
             if (info == 0) then

                !> Prepare working storage
                lwork = nint(real(work_dummy(1),kind=qp),kind=ilp)
                allocate (work(lwork))

                !> Compute eigensystem
                call ggev(task_u,task_v,n,amat,lda, &
                          bmat,ldb, &
                          lreal,limag, &
                          beta, &
                          umat,ldu,vmat,ldv, &
                          work,lwork,info)
                call handle_ggev_info(err0,info,shape(amat),shape(bmat))

             end if
             
             ! Finalize storage and process output flag
             lambda(:n) = cmplx(lreal(:n),limag(:n),kind=qp)
             
             ! Scale generalized eigenvalues
             lambda(:n) = scale_general_eig(lambda(:n),beta)
             
             ! If the j-th and (j+1)-st eigenvalues form a complex conjugate pair,
             ! ggev returns reals as:
             ! u(j)   = VL(:,j) + i*VL(:,j+1) and
             ! u(j+1) = VL(:,j) - i*VL(:,j+1).
             ! Convert these to complex numbers here.
             if (present(right)) call assign_real_eigenvectors_qp(n,lambda,vmat,right)
             if (present(left)) call assign_real_eigenvectors_qp(n,lambda,umat,left)
         
         end if get_ggev
         
         if (copy_a) deallocate (amat)
         if (copy_b) deallocate (bmat)
         if (present(right)) deallocate (vmat)
         if (present(left)) deallocate (umat)
         call err0%handle(err)

     end subroutine la_eig_generalized_q
     
     !> Return an array of eigenvalues of real symmetric / complex hermitian A
     function la_eigvalsh_q(a,upper_a,err) result(lambda)
         !> Input matrix A[m,n]
         real(qp),intent(in),target :: a(:,:)
         !> [optional] Should the upper/lower half of A be used? Default: lower
         logical(lk),optional,intent(in) :: upper_a
         !> [optional] state return flag. On error if not requested, the code will stop
         type(la_state),intent(out) :: err
         !> Array of singular values
         real(qp),allocatable :: lambda(:)
         
         real(qp),pointer :: amat(:,:)
         integer(ilp) :: m,n,k

         !> Create an internal pointer so the intent of A won't affect the next call
         amat => a

         m = size(a,1,kind=ilp)
         n = size(a,2,kind=ilp)
         k = min(m,n)

         !> Allocate return storage
         allocate (lambda(k))

         !> Compute eigenvalues only
         call la_eigh_q(amat,lambda,upper_a=upper_a,overwrite_a=.false.,err=err)
         
     end function la_eigvalsh_q
     
     !> Return an array of eigenvalues of real symmetric / complex hermitian A
     function la_eigvalsh_noerr_q(a,upper_a) result(lambda)
         !> Input matrix A[m,n]
         real(qp),intent(in),target :: a(:,:)
         !> [optional] Should the upper/lower half of A be used? Default: lower
         logical(lk),optional,intent(in) :: upper_a
         !> Array of singular values
         real(qp),allocatable :: lambda(:)

         real(qp),pointer :: amat(:,:)
         integer(ilp) :: m,n,k

         !> Create an internal pointer so the intent of A won't affect the next call
         amat => a

         m = size(a,1,kind=ilp)
         n = size(a,2,kind=ilp)
         k = min(m,n)

         !> Allocate return storage
         allocate (lambda(k))

         !> Compute eigenvalues only
         call la_eigh_q(amat,lambda,upper_a=upper_a,overwrite_a=.false.)

     end function la_eigvalsh_noerr_q

     !> Eigendecomposition of a real symmetric or complex Hermitian matrix A returning an array `lambda`
     !> of eigenvalues, and optionally right or left eigenvectors.
     subroutine la_eigh_q(a,lambda,vectors,upper_a,overwrite_a,err)
         !> Input matrix A[m,n]
         real(qp),intent(inout),target :: a(:,:)
         !> Array of eigenvalues
         real(qp),intent(out) :: lambda(:)
         !> The columns of vectors contain the orthonormal eigenvectors of A
         real(qp),optional,intent(out),target :: vectors(:,:)
         !> [optional] Can A data be overwritten and destroyed?
         logical(lk),optional,intent(in) :: overwrite_a
         !> [optional] Should the upper/lower half of A be used? Default: lower
         logical(lk),optional,intent(in) :: upper_a
         !> [optional] state return flag. On error if not requested, the code will stop
         type(la_state),optional,intent(out) :: err

         !> Local variables
         type(la_state) :: err0
         integer(ilp) :: m,n,lda,info,k,lwork,neig
         logical(lk) :: copy_a
         character :: triangle,task
         real(qp),target :: work_dummy(1)
         real(qp),allocatable :: work(:)
         real(qp),allocatable :: rwork(:)
         real(qp),pointer :: amat(:,:)

         !> Matrix size
         m = size(a,1,kind=ilp)
         n = size(a,2,kind=ilp)
         k = min(m,n)
         neig = size(lambda,kind=ilp)

         if (.not. (k > 0 .and. m == n)) then
            err0 = la_state(this,LINALG_VALUE_ERROR,'invalid or matrix size a=', [m,n], &
                                                        ', must be square.')
            call err0%handle(err)
            return
         end if

         if (.not. neig >= k) then
            err0 = la_state(this,LINALG_VALUE_ERROR,'eigenvalue array has insufficient size:', &
                                                        ' lambda=',neig,' must be >= n=',n)
            call err0%handle(err)
            return
         end if
        
         ! Check if input A can be overwritten
         if (present(vectors)) then
            ! No need to copy A anyways
            copy_a = .false.
         elseif (present(overwrite_a)) then
            copy_a = .not. overwrite_a
         else
            copy_a = .true._lk
         end if
         
         ! Should we use the upper or lower half of the matrix?
         triangle = symmetric_triangle_task(upper_a)
         
         ! Request for eigenvectors
         task = eigenvectors_task(present(vectors))
         
         if (present(vectors)) then
            
            ! Check size
            if (any(shape(vectors,kind=ilp) < n)) then
               err0 = la_state(this,LINALG_VALUE_ERROR, &
                                        'eigenvector matrix has insufficient size: ', &
                                        shape(vectors),', with n=',n)
               call err0%handle(err)
               return
            end if
            
            ! The input matrix will be overwritten by the vectors.
            ! So, use this one as storage for syev/heev
            amat => vectors
            
            ! Copy data in
            amat(:n,:n) = a(:n,:n)
                        
         elseif (copy_a) then
            ! Initialize a matrix temporary
            allocate (amat(m,n),source=a)
         else
            ! Overwrite A
            amat => a
         end if

         lda = size(amat,1,kind=ilp)

         ! Request workspace size
         lwork = -1_ilp
         call syev(task,triangle,n,amat,lda,lambda,work_dummy,lwork,info)
         call heev_info(err0,info,m,n)

         ! Compute eigenvalues
         if (info == 0) then

            !> Prepare working storage
            lwork = nint(real(work_dummy(1),kind=qp),kind=ilp)
            allocate (work(lwork))

            !> Compute eigensystem
            call syev(task,triangle,n,amat,lda,lambda,work,lwork,info)
            call heev_info(err0,info,m,n)

         end if
         
         ! Finalize storage and process output flag
         if (copy_a) deallocate (amat)
         call err0%handle(err)

     end subroutine la_eigh_q
     
     function la_eigvals_standard_c(a,err) result(lambda)
     !! Return an array of eigenvalues of matrix A.
         !> Input matrix A[m,n]
         complex(sp),intent(in),dimension(:,:),target :: a
         !> [optional] state return flag. On error if not requested, the code will stop
         type(la_state),intent(out) :: err
         !> Array of eigenvalues
         complex(sp),allocatable :: lambda(:)

         !> Create
         complex(sp),pointer,dimension(:,:) :: amat
         integer(ilp) :: m,n,k

         !> Create an internal pointer so the intent of A won't affect the next call
         amat => a
         
         m = size(a,1,kind=ilp)
         n = size(a,2,kind=ilp)
         k = min(m,n)

         !> Allocate return storage
         allocate (lambda(k))

         !> Compute eigenvalues only
         call la_eig_standard_c(amat,lambda,err=err)

     end function la_eigvals_standard_c

     function la_eigvals_noerr_standard_c(a) result(lambda)
     !! Return an array of eigenvalues of matrix A.
         !> Input matrix A[m,n]
         complex(sp),intent(in),dimension(:,:),target :: a
         !> Array of eigenvalues
         complex(sp),allocatable :: lambda(:)

         !> Create
         complex(sp),pointer,dimension(:,:) :: amat
         integer(ilp) :: m,n,k

         !> Create an internal pointer so the intent of A won't affect the next call
         amat => a
         
         m = size(a,1,kind=ilp)
         n = size(a,2,kind=ilp)
         k = min(m,n)

         !> Allocate return storage
         allocate (lambda(k))

         !> Compute eigenvalues only
         call la_eig_standard_c(amat,lambda,overwrite_a=.false.)

     end function la_eigvals_noerr_standard_c

     subroutine la_eig_standard_c(a,lambda,right,left, &
                                                       overwrite_a,err)
     !! Eigendecomposition of matrix A returning an array `lambda` of eigenvalues,
     !! and optionally right or left eigenvectors.
         !> Input matrix A[m,n]
         complex(sp),intent(inout),dimension(:,:),target :: a
         !> Array of eigenvalues
         complex(sp),intent(out) :: lambda(:)
         !> [optional] RIGHT eigenvectors of A (as columns)
         complex(sp),optional,intent(out),target :: right(:,:)
         !> [optional] LEFT eigenvectors of A (as columns)
         complex(sp),optional,intent(out),target :: left(:,:)
         !> [optional] Can A data be overwritten and destroyed? (default: no)
         logical(lk),optional,intent(in) :: overwrite_a
         !> [optional] state return flag. On error if not requested, the code will stop
         type(la_state),optional,intent(out) :: err

         !> Local variables
         type(la_state) :: err0
         integer(ilp) :: m,n,lda,ldu,ldv,info,k,lwork,neig
         logical(lk) :: copy_a
         character :: task_u,task_v
         complex(sp),target :: work_dummy(1),u_dummy(1,1),v_dummy(1,1)
         complex(sp),allocatable :: work(:)
         complex(sp),dimension(:,:),pointer :: amat,umat,vmat
         real(sp),allocatable :: rwork(:)
         
         !> Matrix size
         m = size(a,1,kind=ilp)
         n = size(a,2,kind=ilp)
         k = min(m,n)
         neig = size(lambda,kind=ilp)
         lda = m

         if (k <= 0 .or. m /= n) then
            err0 = la_state(this,LINALG_VALUE_ERROR, &
                                          'invalid or matrix size a=', [m,n],', must be nonempty square.')
            call err0%handle(err)
            return
         elseif (neig < k) then
            err0 = la_state(this,LINALG_VALUE_ERROR, &
                                          'eigenvalue array has insufficient size:', &
                                          ' lambda=',neig,', n=',n)
            call err0%handle(err)
            return
         end if
         
         ! Can A be overwritten? By default, do not overwrite
         copy_a = .true._lk
         if (present(overwrite_a)) copy_a = .not. overwrite_a
         
         ! Initialize a matrix temporary
         if (copy_a) then
            allocate (amat(m,n),source=a)
         else
            amat => a
         end if

         ! Decide if U, V eigenvectors
         task_u = eigenvectors_task(present(left))
         task_v = eigenvectors_task(present(right))
         
         if (present(right)) then
                        
            ! For a complex matrix, GEEV returns complex arrays.
            ! Point directly to output.
            vmat => right
            
            if (size(vmat,2,kind=ilp) < n) then
               err0 = la_state(this,LINALG_VALUE_ERROR, &
                                        'right eigenvector matrix has insufficient size: ', &
                                        shape(vmat),', with n=',n)
            end if
            
         else
            vmat => v_dummy
         end if
            
         if (present(left)) then
            
            ! For a complex matrix, GEEV returns complex arrays.
            ! Point directly to output.
            umat => left

            if (size(umat,2,kind=ilp) < n) then
               err0 = la_state(this,LINALG_VALUE_ERROR, &
                                        'left eigenvector matrix has insufficient size: ', &
                                        shape(umat),', with n=',n)
            end if
            
         else
            umat => u_dummy
         end if
         
         get_geev: if (err0%ok()) then

             ldu = size(umat,1,kind=ilp)
             ldv = size(vmat,1,kind=ilp)

             ! Compute workspace size
             allocate (rwork(2*n))
             
             lwork = -1_ilp
            
             call geev(task_u,task_v,n,amat,lda, &
                       lambda, &
                       umat,ldu,vmat,ldv, &
                       work_dummy,lwork,rwork,info)
             call handle_geev_info(err0,info,shape(amat))

             ! Compute eigenvalues
             if (info == 0) then

                !> Prepare working storage
                lwork = nint(real(work_dummy(1),kind=sp),kind=ilp)
                allocate (work(lwork))

                !> Compute eigensystem
                call geev(task_u,task_v,n,amat,lda, &
                          lambda, &
                          umat,ldu,vmat,ldv, &
                          work,lwork,rwork,info)
                call handle_geev_info(err0,info,shape(amat))

             end if
             
             ! Finalize storage and process output flag
             
         end if get_geev
         
         if (copy_a) deallocate (amat)
         call err0%handle(err)

     end subroutine la_eig_standard_c
     
     function la_eigvals_generalized_c(a,b,err) result(lambda)
     !! Return an array of eigenvalues of matrix A.
         !> Input matrix A[m,n]
         complex(sp),intent(in),dimension(:,:),target :: a
         !> Generalized problem matrix B[n,n]
         complex(sp),intent(inout),dimension(:,:),target :: b
         !> [optional] state return flag. On error if not requested, the code will stop
         type(la_state),intent(out) :: err
         !> Array of eigenvalues
         complex(sp),allocatable :: lambda(:)

         !> Create
         complex(sp),pointer,dimension(:,:) :: amat,bmat
         integer(ilp) :: m,n,k

         !> Create an internal pointer so the intent of A won't affect the next call
         amat => a
         bmat => b

         m = size(a,1,kind=ilp)
         n = size(a,2,kind=ilp)
         k = min(m,n)

         !> Allocate return storage
         allocate (lambda(k))

         !> Compute eigenvalues only
         call la_eig_generalized_c(amat,bmat,lambda,err=err)

     end function la_eigvals_generalized_c

     function la_eigvals_noerr_generalized_c(a,b) result(lambda)
     !! Return an array of eigenvalues of matrix A.
         !> Input matrix A[m,n]
         complex(sp),intent(in),dimension(:,:),target :: a
         !> Generalized problem matrix B[n,n]
         complex(sp),intent(inout),dimension(:,:),target :: b
         !> Array of eigenvalues
         complex(sp),allocatable :: lambda(:)

         !> Create
         complex(sp),pointer,dimension(:,:) :: amat,bmat
         integer(ilp) :: m,n,k

         !> Create an internal pointer so the intent of A won't affect the next call
         amat => a
         bmat => b

         m = size(a,1,kind=ilp)
         n = size(a,2,kind=ilp)
         k = min(m,n)

         !> Allocate return storage
         allocate (lambda(k))

         !> Compute eigenvalues only
         call la_eig_generalized_c(amat,bmat,lambda,overwrite_a=.false.)

     end function la_eigvals_noerr_generalized_c

     subroutine la_eig_generalized_c(a,b,lambda,right,left, &
                                                       overwrite_a,overwrite_b,err)
     !! Eigendecomposition of matrix A returning an array `lambda` of eigenvalues,
     !! and optionally right or left eigenvectors.
         !> Input matrix A[m,n]
         complex(sp),intent(inout),dimension(:,:),target :: a
         !> Generalized problem matrix B[n,n]
         complex(sp),intent(inout),dimension(:,:),target :: b
         !> Array of eigenvalues
         complex(sp),intent(out) :: lambda(:)
         !> [optional] RIGHT eigenvectors of A (as columns)
         complex(sp),optional,intent(out),target :: right(:,:)
         !> [optional] LEFT eigenvectors of A (as columns)
         complex(sp),optional,intent(out),target :: left(:,:)
         !> [optional] Can A data be overwritten and destroyed? (default: no)
         logical(lk),optional,intent(in) :: overwrite_a
         !> [optional] Can B data be overwritten and destroyed? (default: no)
         logical(lk),optional,intent(in) :: overwrite_b
         !> [optional] state return flag. On error if not requested, the code will stop
         type(la_state),optional,intent(out) :: err

         !> Local variables
         type(la_state) :: err0
         integer(ilp) :: m,n,lda,ldu,ldv,info,k,lwork,neig,ldb,nb
         logical(lk) :: copy_a,copy_b
         character :: task_u,task_v
         complex(sp),target :: work_dummy(1),u_dummy(1,1),v_dummy(1,1)
         complex(sp),allocatable :: work(:)
         complex(sp),dimension(:,:),pointer :: amat,umat,vmat,bmat
         real(sp),allocatable :: rwork(:)
         complex(sp),allocatable :: beta(:)
         
         !> Matrix size
         m = size(a,1,kind=ilp)
         n = size(a,2,kind=ilp)
         k = min(m,n)
         neig = size(lambda,kind=ilp)
         lda = m

         if (k <= 0 .or. m /= n) then
            err0 = la_state(this,LINALG_VALUE_ERROR, &
                                          'invalid or matrix size a=', [m,n],', must be nonempty square.')
            call err0%handle(err)
            return
         elseif (neig < k) then
            err0 = la_state(this,LINALG_VALUE_ERROR, &
                                          'eigenvalue array has insufficient size:', &
                                          ' lambda=',neig,', n=',n)
            call err0%handle(err)
            return
         end if
         
         ldb = size(b,1,kind=ilp)
         nb = size(b,2,kind=ilp)
         if (ldb /= n .or. nb /= n) then
            err0 = la_state(this,LINALG_VALUE_ERROR, &
                                          'invalid or matrix size b=', [ldb,nb],', must be same as a=', [m,n])
            call err0%handle(err)
            return
         end if

         ! Can A be overwritten? By default, do not overwrite
         copy_a = .true._lk
         if (present(overwrite_a)) copy_a = .not. overwrite_a
         
         ! Initialize a matrix temporary
         if (copy_a) then
            allocate (amat(m,n),source=a)
         else
            amat => a
         end if

         ! Can B be overwritten? By default, do not overwrite
         copy_b = .true._lk
         if (present(overwrite_b)) copy_b = .not. overwrite_b
         
         ! Initialize a matrix temporary
         if (copy_b) then
            allocate (bmat,source=b)
         else
            bmat => b
         end if
         allocate (beta(n))

         ! Decide if U, V eigenvectors
         task_u = eigenvectors_task(present(left))
         task_v = eigenvectors_task(present(right))
         
         if (present(right)) then
                        
            ! For a complex matrix, GEEV returns complex arrays.
            ! Point directly to output.
            vmat => right
            
            if (size(vmat,2,kind=ilp) < n) then
               err0 = la_state(this,LINALG_VALUE_ERROR, &
                                        'right eigenvector matrix has insufficient size: ', &
                                        shape(vmat),', with n=',n)
            end if
            
         else
            vmat => v_dummy
         end if
            
         if (present(left)) then
            
            ! For a complex matrix, GEEV returns complex arrays.
            ! Point directly to output.
            umat => left

            if (size(umat,2,kind=ilp) < n) then
               err0 = la_state(this,LINALG_VALUE_ERROR, &
                                        'left eigenvector matrix has insufficient size: ', &
                                        shape(umat),', with n=',n)
            end if
            
         else
            umat => u_dummy
         end if
         
         get_ggev: if (err0%ok()) then

             ldu = size(umat,1,kind=ilp)
             ldv = size(vmat,1,kind=ilp)

             ! Compute workspace size
             allocate (rwork(8*n))
             
             lwork = -1_ilp
            
             call ggev(task_u,task_v,n,amat,lda, &
                       bmat,ldb, &
                       lambda, &
                       beta, &
                       umat,ldu,vmat,ldv, &
                       work_dummy,lwork,rwork,info)
             call handle_ggev_info(err0,info,shape(amat),shape(bmat))

             ! Compute eigenvalues
             if (info == 0) then

                !> Prepare working storage
                lwork = nint(real(work_dummy(1),kind=sp),kind=ilp)
                allocate (work(lwork))

                !> Compute eigensystem
                call ggev(task_u,task_v,n,amat,lda, &
                          bmat,ldb, &
                          lambda, &
                          beta, &
                          umat,ldu,vmat,ldv, &
                          work,lwork,rwork,info)
                call handle_ggev_info(err0,info,shape(amat),shape(bmat))

             end if
             
             ! Finalize storage and process output flag
             
             ! Scale generalized eigenvalues
             lambda(:n) = scale_general_eig(lambda(:n),beta)
             
         end if get_ggev
         
         if (copy_a) deallocate (amat)
         if (copy_b) deallocate (bmat)
         call err0%handle(err)

     end subroutine la_eig_generalized_c
     
     !> Return an array of eigenvalues of real symmetric / complex hermitian A
     function la_eigvalsh_c(a,upper_a,err) result(lambda)
         !> Input matrix A[m,n]
         complex(sp),intent(in),target :: a(:,:)
         !> [optional] Should the upper/lower half of A be used? Default: lower
         logical(lk),optional,intent(in) :: upper_a
         !> [optional] state return flag. On error if not requested, the code will stop
         type(la_state),intent(out) :: err
         !> Array of singular values
         real(sp),allocatable :: lambda(:)
         
         complex(sp),pointer :: amat(:,:)
         integer(ilp) :: m,n,k

         !> Create an internal pointer so the intent of A won't affect the next call
         amat => a

         m = size(a,1,kind=ilp)
         n = size(a,2,kind=ilp)
         k = min(m,n)

         !> Allocate return storage
         allocate (lambda(k))

         !> Compute eigenvalues only
         call la_eigh_c(amat,lambda,upper_a=upper_a,overwrite_a=.false.,err=err)
         
     end function la_eigvalsh_c
     
     !> Return an array of eigenvalues of real symmetric / complex hermitian A
     function la_eigvalsh_noerr_c(a,upper_a) result(lambda)
         !> Input matrix A[m,n]
         complex(sp),intent(in),target :: a(:,:)
         !> [optional] Should the upper/lower half of A be used? Default: lower
         logical(lk),optional,intent(in) :: upper_a
         !> Array of singular values
         real(sp),allocatable :: lambda(:)

         complex(sp),pointer :: amat(:,:)
         integer(ilp) :: m,n,k

         !> Create an internal pointer so the intent of A won't affect the next call
         amat => a

         m = size(a,1,kind=ilp)
         n = size(a,2,kind=ilp)
         k = min(m,n)

         !> Allocate return storage
         allocate (lambda(k))

         !> Compute eigenvalues only
         call la_eigh_c(amat,lambda,upper_a=upper_a,overwrite_a=.false.)

     end function la_eigvalsh_noerr_c

     !> Eigendecomposition of a real symmetric or complex Hermitian matrix A returning an array `lambda`
     !> of eigenvalues, and optionally right or left eigenvectors.
     subroutine la_eigh_c(a,lambda,vectors,upper_a,overwrite_a,err)
         !> Input matrix A[m,n]
         complex(sp),intent(inout),target :: a(:,:)
         !> Array of eigenvalues
         real(sp),intent(out) :: lambda(:)
         !> The columns of vectors contain the orthonormal eigenvectors of A
         complex(sp),optional,intent(out),target :: vectors(:,:)
         !> [optional] Can A data be overwritten and destroyed?
         logical(lk),optional,intent(in) :: overwrite_a
         !> [optional] Should the upper/lower half of A be used? Default: lower
         logical(lk),optional,intent(in) :: upper_a
         !> [optional] state return flag. On error if not requested, the code will stop
         type(la_state),optional,intent(out) :: err

         !> Local variables
         type(la_state) :: err0
         integer(ilp) :: m,n,lda,info,k,lwork,neig
         logical(lk) :: copy_a
         character :: triangle,task
         complex(sp),target :: work_dummy(1)
         complex(sp),allocatable :: work(:)
         real(sp),allocatable :: rwork(:)
         complex(sp),pointer :: amat(:,:)

         !> Matrix size
         m = size(a,1,kind=ilp)
         n = size(a,2,kind=ilp)
         k = min(m,n)
         neig = size(lambda,kind=ilp)

         if (.not. (k > 0 .and. m == n)) then
            err0 = la_state(this,LINALG_VALUE_ERROR,'invalid or matrix size a=', [m,n], &
                                                        ', must be square.')
            call err0%handle(err)
            return
         end if

         if (.not. neig >= k) then
            err0 = la_state(this,LINALG_VALUE_ERROR,'eigenvalue array has insufficient size:', &
                                                        ' lambda=',neig,' must be >= n=',n)
            call err0%handle(err)
            return
         end if
        
         ! Check if input A can be overwritten
         if (present(vectors)) then
            ! No need to copy A anyways
            copy_a = .false.
         elseif (present(overwrite_a)) then
            copy_a = .not. overwrite_a
         else
            copy_a = .true._lk
         end if
         
         ! Should we use the upper or lower half of the matrix?
         triangle = symmetric_triangle_task(upper_a)
         
         ! Request for eigenvectors
         task = eigenvectors_task(present(vectors))
         
         if (present(vectors)) then
            
            ! Check size
            if (any(shape(vectors,kind=ilp) < n)) then
               err0 = la_state(this,LINALG_VALUE_ERROR, &
                                        'eigenvector matrix has insufficient size: ', &
                                        shape(vectors),', with n=',n)
               call err0%handle(err)
               return
            end if
            
            ! The input matrix will be overwritten by the vectors.
            ! So, use this one as storage for syev/heev
            amat => vectors
            
            ! Copy data in
            amat(:n,:n) = a(:n,:n)
                        
         elseif (copy_a) then
            ! Initialize a matrix temporary
            allocate (amat(m,n),source=a)
         else
            ! Overwrite A
            amat => a
         end if

         lda = size(amat,1,kind=ilp)

         ! Request workspace size
         lwork = -1_ilp
         allocate (rwork(max(1,3*n - 2)))
         call heev(task,triangle,n,amat,lda,lambda,work_dummy,lwork,rwork,info)
         call heev_info(err0,info,m,n)

         ! Compute eigenvalues
         if (info == 0) then

            !> Prepare working storage
            lwork = nint(real(work_dummy(1),kind=sp),kind=ilp)
            allocate (work(lwork))

            !> Compute eigensystem
            call heev(task,triangle,n,amat,lda,lambda,work,lwork,rwork,info)
            call heev_info(err0,info,m,n)

         end if
         
         ! Finalize storage and process output flag
         if (copy_a) deallocate (amat)
         call err0%handle(err)

     end subroutine la_eigh_c
     
     function la_eigvals_standard_z(a,err) result(lambda)
     !! Return an array of eigenvalues of matrix A.
         !> Input matrix A[m,n]
         complex(dp),intent(in),dimension(:,:),target :: a
         !> [optional] state return flag. On error if not requested, the code will stop
         type(la_state),intent(out) :: err
         !> Array of eigenvalues
         complex(dp),allocatable :: lambda(:)

         !> Create
         complex(dp),pointer,dimension(:,:) :: amat
         integer(ilp) :: m,n,k

         !> Create an internal pointer so the intent of A won't affect the next call
         amat => a
         
         m = size(a,1,kind=ilp)
         n = size(a,2,kind=ilp)
         k = min(m,n)

         !> Allocate return storage
         allocate (lambda(k))

         !> Compute eigenvalues only
         call la_eig_standard_z(amat,lambda,err=err)

     end function la_eigvals_standard_z

     function la_eigvals_noerr_standard_z(a) result(lambda)
     !! Return an array of eigenvalues of matrix A.
         !> Input matrix A[m,n]
         complex(dp),intent(in),dimension(:,:),target :: a
         !> Array of eigenvalues
         complex(dp),allocatable :: lambda(:)

         !> Create
         complex(dp),pointer,dimension(:,:) :: amat
         integer(ilp) :: m,n,k

         !> Create an internal pointer so the intent of A won't affect the next call
         amat => a
         
         m = size(a,1,kind=ilp)
         n = size(a,2,kind=ilp)
         k = min(m,n)

         !> Allocate return storage
         allocate (lambda(k))

         !> Compute eigenvalues only
         call la_eig_standard_z(amat,lambda,overwrite_a=.false.)

     end function la_eigvals_noerr_standard_z

     subroutine la_eig_standard_z(a,lambda,right,left, &
                                                       overwrite_a,err)
     !! Eigendecomposition of matrix A returning an array `lambda` of eigenvalues,
     !! and optionally right or left eigenvectors.
         !> Input matrix A[m,n]
         complex(dp),intent(inout),dimension(:,:),target :: a
         !> Array of eigenvalues
         complex(dp),intent(out) :: lambda(:)
         !> [optional] RIGHT eigenvectors of A (as columns)
         complex(dp),optional,intent(out),target :: right(:,:)
         !> [optional] LEFT eigenvectors of A (as columns)
         complex(dp),optional,intent(out),target :: left(:,:)
         !> [optional] Can A data be overwritten and destroyed? (default: no)
         logical(lk),optional,intent(in) :: overwrite_a
         !> [optional] state return flag. On error if not requested, the code will stop
         type(la_state),optional,intent(out) :: err

         !> Local variables
         type(la_state) :: err0
         integer(ilp) :: m,n,lda,ldu,ldv,info,k,lwork,neig
         logical(lk) :: copy_a
         character :: task_u,task_v
         complex(dp),target :: work_dummy(1),u_dummy(1,1),v_dummy(1,1)
         complex(dp),allocatable :: work(:)
         complex(dp),dimension(:,:),pointer :: amat,umat,vmat
         real(dp),allocatable :: rwork(:)
         
         !> Matrix size
         m = size(a,1,kind=ilp)
         n = size(a,2,kind=ilp)
         k = min(m,n)
         neig = size(lambda,kind=ilp)
         lda = m

         if (k <= 0 .or. m /= n) then
            err0 = la_state(this,LINALG_VALUE_ERROR, &
                                          'invalid or matrix size a=', [m,n],', must be nonempty square.')
            call err0%handle(err)
            return
         elseif (neig < k) then
            err0 = la_state(this,LINALG_VALUE_ERROR, &
                                          'eigenvalue array has insufficient size:', &
                                          ' lambda=',neig,', n=',n)
            call err0%handle(err)
            return
         end if
         
         ! Can A be overwritten? By default, do not overwrite
         copy_a = .true._lk
         if (present(overwrite_a)) copy_a = .not. overwrite_a
         
         ! Initialize a matrix temporary
         if (copy_a) then
            allocate (amat(m,n),source=a)
         else
            amat => a
         end if

         ! Decide if U, V eigenvectors
         task_u = eigenvectors_task(present(left))
         task_v = eigenvectors_task(present(right))
         
         if (present(right)) then
                        
            ! For a complex matrix, GEEV returns complex arrays.
            ! Point directly to output.
            vmat => right
            
            if (size(vmat,2,kind=ilp) < n) then
               err0 = la_state(this,LINALG_VALUE_ERROR, &
                                        'right eigenvector matrix has insufficient size: ', &
                                        shape(vmat),', with n=',n)
            end if
            
         else
            vmat => v_dummy
         end if
            
         if (present(left)) then
            
            ! For a complex matrix, GEEV returns complex arrays.
            ! Point directly to output.
            umat => left

            if (size(umat,2,kind=ilp) < n) then
               err0 = la_state(this,LINALG_VALUE_ERROR, &
                                        'left eigenvector matrix has insufficient size: ', &
                                        shape(umat),', with n=',n)
            end if
            
         else
            umat => u_dummy
         end if
         
         get_geev: if (err0%ok()) then

             ldu = size(umat,1,kind=ilp)
             ldv = size(vmat,1,kind=ilp)

             ! Compute workspace size
             allocate (rwork(2*n))
             
             lwork = -1_ilp
            
             call geev(task_u,task_v,n,amat,lda, &
                       lambda, &
                       umat,ldu,vmat,ldv, &
                       work_dummy,lwork,rwork,info)
             call handle_geev_info(err0,info,shape(amat))

             ! Compute eigenvalues
             if (info == 0) then

                !> Prepare working storage
                lwork = nint(real(work_dummy(1),kind=dp),kind=ilp)
                allocate (work(lwork))

                !> Compute eigensystem
                call geev(task_u,task_v,n,amat,lda, &
                          lambda, &
                          umat,ldu,vmat,ldv, &
                          work,lwork,rwork,info)
                call handle_geev_info(err0,info,shape(amat))

             end if
             
             ! Finalize storage and process output flag
             
         end if get_geev
         
         if (copy_a) deallocate (amat)
         call err0%handle(err)

     end subroutine la_eig_standard_z
     
     function la_eigvals_generalized_z(a,b,err) result(lambda)
     !! Return an array of eigenvalues of matrix A.
         !> Input matrix A[m,n]
         complex(dp),intent(in),dimension(:,:),target :: a
         !> Generalized problem matrix B[n,n]
         complex(dp),intent(inout),dimension(:,:),target :: b
         !> [optional] state return flag. On error if not requested, the code will stop
         type(la_state),intent(out) :: err
         !> Array of eigenvalues
         complex(dp),allocatable :: lambda(:)

         !> Create
         complex(dp),pointer,dimension(:,:) :: amat,bmat
         integer(ilp) :: m,n,k

         !> Create an internal pointer so the intent of A won't affect the next call
         amat => a
         bmat => b

         m = size(a,1,kind=ilp)
         n = size(a,2,kind=ilp)
         k = min(m,n)

         !> Allocate return storage
         allocate (lambda(k))

         !> Compute eigenvalues only
         call la_eig_generalized_z(amat,bmat,lambda,err=err)

     end function la_eigvals_generalized_z

     function la_eigvals_noerr_generalized_z(a,b) result(lambda)
     !! Return an array of eigenvalues of matrix A.
         !> Input matrix A[m,n]
         complex(dp),intent(in),dimension(:,:),target :: a
         !> Generalized problem matrix B[n,n]
         complex(dp),intent(inout),dimension(:,:),target :: b
         !> Array of eigenvalues
         complex(dp),allocatable :: lambda(:)

         !> Create
         complex(dp),pointer,dimension(:,:) :: amat,bmat
         integer(ilp) :: m,n,k

         !> Create an internal pointer so the intent of A won't affect the next call
         amat => a
         bmat => b

         m = size(a,1,kind=ilp)
         n = size(a,2,kind=ilp)
         k = min(m,n)

         !> Allocate return storage
         allocate (lambda(k))

         !> Compute eigenvalues only
         call la_eig_generalized_z(amat,bmat,lambda,overwrite_a=.false.)

     end function la_eigvals_noerr_generalized_z

     subroutine la_eig_generalized_z(a,b,lambda,right,left, &
                                                       overwrite_a,overwrite_b,err)
     !! Eigendecomposition of matrix A returning an array `lambda` of eigenvalues,
     !! and optionally right or left eigenvectors.
         !> Input matrix A[m,n]
         complex(dp),intent(inout),dimension(:,:),target :: a
         !> Generalized problem matrix B[n,n]
         complex(dp),intent(inout),dimension(:,:),target :: b
         !> Array of eigenvalues
         complex(dp),intent(out) :: lambda(:)
         !> [optional] RIGHT eigenvectors of A (as columns)
         complex(dp),optional,intent(out),target :: right(:,:)
         !> [optional] LEFT eigenvectors of A (as columns)
         complex(dp),optional,intent(out),target :: left(:,:)
         !> [optional] Can A data be overwritten and destroyed? (default: no)
         logical(lk),optional,intent(in) :: overwrite_a
         !> [optional] Can B data be overwritten and destroyed? (default: no)
         logical(lk),optional,intent(in) :: overwrite_b
         !> [optional] state return flag. On error if not requested, the code will stop
         type(la_state),optional,intent(out) :: err

         !> Local variables
         type(la_state) :: err0
         integer(ilp) :: m,n,lda,ldu,ldv,info,k,lwork,neig,ldb,nb
         logical(lk) :: copy_a,copy_b
         character :: task_u,task_v
         complex(dp),target :: work_dummy(1),u_dummy(1,1),v_dummy(1,1)
         complex(dp),allocatable :: work(:)
         complex(dp),dimension(:,:),pointer :: amat,umat,vmat,bmat
         real(dp),allocatable :: rwork(:)
         complex(dp),allocatable :: beta(:)
         
         !> Matrix size
         m = size(a,1,kind=ilp)
         n = size(a,2,kind=ilp)
         k = min(m,n)
         neig = size(lambda,kind=ilp)
         lda = m

         if (k <= 0 .or. m /= n) then
            err0 = la_state(this,LINALG_VALUE_ERROR, &
                                          'invalid or matrix size a=', [m,n],', must be nonempty square.')
            call err0%handle(err)
            return
         elseif (neig < k) then
            err0 = la_state(this,LINALG_VALUE_ERROR, &
                                          'eigenvalue array has insufficient size:', &
                                          ' lambda=',neig,', n=',n)
            call err0%handle(err)
            return
         end if
         
         ldb = size(b,1,kind=ilp)
         nb = size(b,2,kind=ilp)
         if (ldb /= n .or. nb /= n) then
            err0 = la_state(this,LINALG_VALUE_ERROR, &
                                          'invalid or matrix size b=', [ldb,nb],', must be same as a=', [m,n])
            call err0%handle(err)
            return
         end if

         ! Can A be overwritten? By default, do not overwrite
         copy_a = .true._lk
         if (present(overwrite_a)) copy_a = .not. overwrite_a
         
         ! Initialize a matrix temporary
         if (copy_a) then
            allocate (amat(m,n),source=a)
         else
            amat => a
         end if

         ! Can B be overwritten? By default, do not overwrite
         copy_b = .true._lk
         if (present(overwrite_b)) copy_b = .not. overwrite_b
         
         ! Initialize a matrix temporary
         if (copy_b) then
            allocate (bmat,source=b)
         else
            bmat => b
         end if
         allocate (beta(n))

         ! Decide if U, V eigenvectors
         task_u = eigenvectors_task(present(left))
         task_v = eigenvectors_task(present(right))
         
         if (present(right)) then
                        
            ! For a complex matrix, GEEV returns complex arrays.
            ! Point directly to output.
            vmat => right
            
            if (size(vmat,2,kind=ilp) < n) then
               err0 = la_state(this,LINALG_VALUE_ERROR, &
                                        'right eigenvector matrix has insufficient size: ', &
                                        shape(vmat),', with n=',n)
            end if
            
         else
            vmat => v_dummy
         end if
            
         if (present(left)) then
            
            ! For a complex matrix, GEEV returns complex arrays.
            ! Point directly to output.
            umat => left

            if (size(umat,2,kind=ilp) < n) then
               err0 = la_state(this,LINALG_VALUE_ERROR, &
                                        'left eigenvector matrix has insufficient size: ', &
                                        shape(umat),', with n=',n)
            end if
            
         else
            umat => u_dummy
         end if
         
         get_ggev: if (err0%ok()) then

             ldu = size(umat,1,kind=ilp)
             ldv = size(vmat,1,kind=ilp)

             ! Compute workspace size
             allocate (rwork(8*n))
             
             lwork = -1_ilp
            
             call ggev(task_u,task_v,n,amat,lda, &
                       bmat,ldb, &
                       lambda, &
                       beta, &
                       umat,ldu,vmat,ldv, &
                       work_dummy,lwork,rwork,info)
             call handle_ggev_info(err0,info,shape(amat),shape(bmat))

             ! Compute eigenvalues
             if (info == 0) then

                !> Prepare working storage
                lwork = nint(real(work_dummy(1),kind=dp),kind=ilp)
                allocate (work(lwork))

                !> Compute eigensystem
                call ggev(task_u,task_v,n,amat,lda, &
                          bmat,ldb, &
                          lambda, &
                          beta, &
                          umat,ldu,vmat,ldv, &
                          work,lwork,rwork,info)
                call handle_ggev_info(err0,info,shape(amat),shape(bmat))

             end if
             
             ! Finalize storage and process output flag
             
             ! Scale generalized eigenvalues
             lambda(:n) = scale_general_eig(lambda(:n),beta)
             
         end if get_ggev
         
         if (copy_a) deallocate (amat)
         if (copy_b) deallocate (bmat)
         call err0%handle(err)

     end subroutine la_eig_generalized_z
     
     !> Return an array of eigenvalues of real symmetric / complex hermitian A
     function la_eigvalsh_z(a,upper_a,err) result(lambda)
         !> Input matrix A[m,n]
         complex(dp),intent(in),target :: a(:,:)
         !> [optional] Should the upper/lower half of A be used? Default: lower
         logical(lk),optional,intent(in) :: upper_a
         !> [optional] state return flag. On error if not requested, the code will stop
         type(la_state),intent(out) :: err
         !> Array of singular values
         real(dp),allocatable :: lambda(:)
         
         complex(dp),pointer :: amat(:,:)
         integer(ilp) :: m,n,k

         !> Create an internal pointer so the intent of A won't affect the next call
         amat => a

         m = size(a,1,kind=ilp)
         n = size(a,2,kind=ilp)
         k = min(m,n)

         !> Allocate return storage
         allocate (lambda(k))

         !> Compute eigenvalues only
         call la_eigh_z(amat,lambda,upper_a=upper_a,overwrite_a=.false.,err=err)
         
     end function la_eigvalsh_z
     
     !> Return an array of eigenvalues of real symmetric / complex hermitian A
     function la_eigvalsh_noerr_z(a,upper_a) result(lambda)
         !> Input matrix A[m,n]
         complex(dp),intent(in),target :: a(:,:)
         !> [optional] Should the upper/lower half of A be used? Default: lower
         logical(lk),optional,intent(in) :: upper_a
         !> Array of singular values
         real(dp),allocatable :: lambda(:)

         complex(dp),pointer :: amat(:,:)
         integer(ilp) :: m,n,k

         !> Create an internal pointer so the intent of A won't affect the next call
         amat => a

         m = size(a,1,kind=ilp)
         n = size(a,2,kind=ilp)
         k = min(m,n)

         !> Allocate return storage
         allocate (lambda(k))

         !> Compute eigenvalues only
         call la_eigh_z(amat,lambda,upper_a=upper_a,overwrite_a=.false.)

     end function la_eigvalsh_noerr_z

     !> Eigendecomposition of a real symmetric or complex Hermitian matrix A returning an array `lambda`
     !> of eigenvalues, and optionally right or left eigenvectors.
     subroutine la_eigh_z(a,lambda,vectors,upper_a,overwrite_a,err)
         !> Input matrix A[m,n]
         complex(dp),intent(inout),target :: a(:,:)
         !> Array of eigenvalues
         real(dp),intent(out) :: lambda(:)
         !> The columns of vectors contain the orthonormal eigenvectors of A
         complex(dp),optional,intent(out),target :: vectors(:,:)
         !> [optional] Can A data be overwritten and destroyed?
         logical(lk),optional,intent(in) :: overwrite_a
         !> [optional] Should the upper/lower half of A be used? Default: lower
         logical(lk),optional,intent(in) :: upper_a
         !> [optional] state return flag. On error if not requested, the code will stop
         type(la_state),optional,intent(out) :: err

         !> Local variables
         type(la_state) :: err0
         integer(ilp) :: m,n,lda,info,k,lwork,neig
         logical(lk) :: copy_a
         character :: triangle,task
         complex(dp),target :: work_dummy(1)
         complex(dp),allocatable :: work(:)
         real(dp),allocatable :: rwork(:)
         complex(dp),pointer :: amat(:,:)

         !> Matrix size
         m = size(a,1,kind=ilp)
         n = size(a,2,kind=ilp)
         k = min(m,n)
         neig = size(lambda,kind=ilp)

         if (.not. (k > 0 .and. m == n)) then
            err0 = la_state(this,LINALG_VALUE_ERROR,'invalid or matrix size a=', [m,n], &
                                                        ', must be square.')
            call err0%handle(err)
            return
         end if

         if (.not. neig >= k) then
            err0 = la_state(this,LINALG_VALUE_ERROR,'eigenvalue array has insufficient size:', &
                                                        ' lambda=',neig,' must be >= n=',n)
            call err0%handle(err)
            return
         end if
        
         ! Check if input A can be overwritten
         if (present(vectors)) then
            ! No need to copy A anyways
            copy_a = .false.
         elseif (present(overwrite_a)) then
            copy_a = .not. overwrite_a
         else
            copy_a = .true._lk
         end if
         
         ! Should we use the upper or lower half of the matrix?
         triangle = symmetric_triangle_task(upper_a)
         
         ! Request for eigenvectors
         task = eigenvectors_task(present(vectors))
         
         if (present(vectors)) then
            
            ! Check size
            if (any(shape(vectors,kind=ilp) < n)) then
               err0 = la_state(this,LINALG_VALUE_ERROR, &
                                        'eigenvector matrix has insufficient size: ', &
                                        shape(vectors),', with n=',n)
               call err0%handle(err)
               return
            end if
            
            ! The input matrix will be overwritten by the vectors.
            ! So, use this one as storage for syev/heev
            amat => vectors
            
            ! Copy data in
            amat(:n,:n) = a(:n,:n)
                        
         elseif (copy_a) then
            ! Initialize a matrix temporary
            allocate (amat(m,n),source=a)
         else
            ! Overwrite A
            amat => a
         end if

         lda = size(amat,1,kind=ilp)

         ! Request workspace size
         lwork = -1_ilp
         allocate (rwork(max(1,3*n - 2)))
         call heev(task,triangle,n,amat,lda,lambda,work_dummy,lwork,rwork,info)
         call heev_info(err0,info,m,n)

         ! Compute eigenvalues
         if (info == 0) then

            !> Prepare working storage
            lwork = nint(real(work_dummy(1),kind=dp),kind=ilp)
            allocate (work(lwork))

            !> Compute eigensystem
            call heev(task,triangle,n,amat,lda,lambda,work,lwork,rwork,info)
            call heev_info(err0,info,m,n)

         end if
         
         ! Finalize storage and process output flag
         if (copy_a) deallocate (amat)
         call err0%handle(err)

     end subroutine la_eigh_z
     
     function la_eigvals_standard_w(a,err) result(lambda)
     !! Return an array of eigenvalues of matrix A.
         !> Input matrix A[m,n]
         complex(qp),intent(in),dimension(:,:),target :: a
         !> [optional] state return flag. On error if not requested, the code will stop
         type(la_state),intent(out) :: err
         !> Array of eigenvalues
         complex(qp),allocatable :: lambda(:)

         !> Create
         complex(qp),pointer,dimension(:,:) :: amat
         integer(ilp) :: m,n,k

         !> Create an internal pointer so the intent of A won't affect the next call
         amat => a
         
         m = size(a,1,kind=ilp)
         n = size(a,2,kind=ilp)
         k = min(m,n)

         !> Allocate return storage
         allocate (lambda(k))

         !> Compute eigenvalues only
         call la_eig_standard_w(amat,lambda,err=err)

     end function la_eigvals_standard_w

     function la_eigvals_noerr_standard_w(a) result(lambda)
     !! Return an array of eigenvalues of matrix A.
         !> Input matrix A[m,n]
         complex(qp),intent(in),dimension(:,:),target :: a
         !> Array of eigenvalues
         complex(qp),allocatable :: lambda(:)

         !> Create
         complex(qp),pointer,dimension(:,:) :: amat
         integer(ilp) :: m,n,k

         !> Create an internal pointer so the intent of A won't affect the next call
         amat => a
         
         m = size(a,1,kind=ilp)
         n = size(a,2,kind=ilp)
         k = min(m,n)

         !> Allocate return storage
         allocate (lambda(k))

         !> Compute eigenvalues only
         call la_eig_standard_w(amat,lambda,overwrite_a=.false.)

     end function la_eigvals_noerr_standard_w

     subroutine la_eig_standard_w(a,lambda,right,left, &
                                                       overwrite_a,err)
     !! Eigendecomposition of matrix A returning an array `lambda` of eigenvalues,
     !! and optionally right or left eigenvectors.
         !> Input matrix A[m,n]
         complex(qp),intent(inout),dimension(:,:),target :: a
         !> Array of eigenvalues
         complex(qp),intent(out) :: lambda(:)
         !> [optional] RIGHT eigenvectors of A (as columns)
         complex(qp),optional,intent(out),target :: right(:,:)
         !> [optional] LEFT eigenvectors of A (as columns)
         complex(qp),optional,intent(out),target :: left(:,:)
         !> [optional] Can A data be overwritten and destroyed? (default: no)
         logical(lk),optional,intent(in) :: overwrite_a
         !> [optional] state return flag. On error if not requested, the code will stop
         type(la_state),optional,intent(out) :: err

         !> Local variables
         type(la_state) :: err0
         integer(ilp) :: m,n,lda,ldu,ldv,info,k,lwork,neig
         logical(lk) :: copy_a
         character :: task_u,task_v
         complex(qp),target :: work_dummy(1),u_dummy(1,1),v_dummy(1,1)
         complex(qp),allocatable :: work(:)
         complex(qp),dimension(:,:),pointer :: amat,umat,vmat
         real(qp),allocatable :: rwork(:)
         
         !> Matrix size
         m = size(a,1,kind=ilp)
         n = size(a,2,kind=ilp)
         k = min(m,n)
         neig = size(lambda,kind=ilp)
         lda = m

         if (k <= 0 .or. m /= n) then
            err0 = la_state(this,LINALG_VALUE_ERROR, &
                                          'invalid or matrix size a=', [m,n],', must be nonempty square.')
            call err0%handle(err)
            return
         elseif (neig < k) then
            err0 = la_state(this,LINALG_VALUE_ERROR, &
                                          'eigenvalue array has insufficient size:', &
                                          ' lambda=',neig,', n=',n)
            call err0%handle(err)
            return
         end if
         
         ! Can A be overwritten? By default, do not overwrite
         copy_a = .true._lk
         if (present(overwrite_a)) copy_a = .not. overwrite_a
         
         ! Initialize a matrix temporary
         if (copy_a) then
            allocate (amat(m,n),source=a)
         else
            amat => a
         end if

         ! Decide if U, V eigenvectors
         task_u = eigenvectors_task(present(left))
         task_v = eigenvectors_task(present(right))
         
         if (present(right)) then
                        
            ! For a complex matrix, GEEV returns complex arrays.
            ! Point directly to output.
            vmat => right
            
            if (size(vmat,2,kind=ilp) < n) then
               err0 = la_state(this,LINALG_VALUE_ERROR, &
                                        'right eigenvector matrix has insufficient size: ', &
                                        shape(vmat),', with n=',n)
            end if
            
         else
            vmat => v_dummy
         end if
            
         if (present(left)) then
            
            ! For a complex matrix, GEEV returns complex arrays.
            ! Point directly to output.
            umat => left

            if (size(umat,2,kind=ilp) < n) then
               err0 = la_state(this,LINALG_VALUE_ERROR, &
                                        'left eigenvector matrix has insufficient size: ', &
                                        shape(umat),', with n=',n)
            end if
            
         else
            umat => u_dummy
         end if
         
         get_geev: if (err0%ok()) then

             ldu = size(umat,1,kind=ilp)
             ldv = size(vmat,1,kind=ilp)

             ! Compute workspace size
             allocate (rwork(2*n))
             
             lwork = -1_ilp
            
             call geev(task_u,task_v,n,amat,lda, &
                       lambda, &
                       umat,ldu,vmat,ldv, &
                       work_dummy,lwork,rwork,info)
             call handle_geev_info(err0,info,shape(amat))

             ! Compute eigenvalues
             if (info == 0) then

                !> Prepare working storage
                lwork = nint(real(work_dummy(1),kind=qp),kind=ilp)
                allocate (work(lwork))

                !> Compute eigensystem
                call geev(task_u,task_v,n,amat,lda, &
                          lambda, &
                          umat,ldu,vmat,ldv, &
                          work,lwork,rwork,info)
                call handle_geev_info(err0,info,shape(amat))

             end if
             
             ! Finalize storage and process output flag
             
         end if get_geev
         
         if (copy_a) deallocate (amat)
         call err0%handle(err)

     end subroutine la_eig_standard_w
     
     function la_eigvals_generalized_w(a,b,err) result(lambda)
     !! Return an array of eigenvalues of matrix A.
         !> Input matrix A[m,n]
         complex(qp),intent(in),dimension(:,:),target :: a
         !> Generalized problem matrix B[n,n]
         complex(qp),intent(inout),dimension(:,:),target :: b
         !> [optional] state return flag. On error if not requested, the code will stop
         type(la_state),intent(out) :: err
         !> Array of eigenvalues
         complex(qp),allocatable :: lambda(:)

         !> Create
         complex(qp),pointer,dimension(:,:) :: amat,bmat
         integer(ilp) :: m,n,k

         !> Create an internal pointer so the intent of A won't affect the next call
         amat => a
         bmat => b

         m = size(a,1,kind=ilp)
         n = size(a,2,kind=ilp)
         k = min(m,n)

         !> Allocate return storage
         allocate (lambda(k))

         !> Compute eigenvalues only
         call la_eig_generalized_w(amat,bmat,lambda,err=err)

     end function la_eigvals_generalized_w

     function la_eigvals_noerr_generalized_w(a,b) result(lambda)
     !! Return an array of eigenvalues of matrix A.
         !> Input matrix A[m,n]
         complex(qp),intent(in),dimension(:,:),target :: a
         !> Generalized problem matrix B[n,n]
         complex(qp),intent(inout),dimension(:,:),target :: b
         !> Array of eigenvalues
         complex(qp),allocatable :: lambda(:)

         !> Create
         complex(qp),pointer,dimension(:,:) :: amat,bmat
         integer(ilp) :: m,n,k

         !> Create an internal pointer so the intent of A won't affect the next call
         amat => a
         bmat => b

         m = size(a,1,kind=ilp)
         n = size(a,2,kind=ilp)
         k = min(m,n)

         !> Allocate return storage
         allocate (lambda(k))

         !> Compute eigenvalues only
         call la_eig_generalized_w(amat,bmat,lambda,overwrite_a=.false.)

     end function la_eigvals_noerr_generalized_w

     subroutine la_eig_generalized_w(a,b,lambda,right,left, &
                                                       overwrite_a,overwrite_b,err)
     !! Eigendecomposition of matrix A returning an array `lambda` of eigenvalues,
     !! and optionally right or left eigenvectors.
         !> Input matrix A[m,n]
         complex(qp),intent(inout),dimension(:,:),target :: a
         !> Generalized problem matrix B[n,n]
         complex(qp),intent(inout),dimension(:,:),target :: b
         !> Array of eigenvalues
         complex(qp),intent(out) :: lambda(:)
         !> [optional] RIGHT eigenvectors of A (as columns)
         complex(qp),optional,intent(out),target :: right(:,:)
         !> [optional] LEFT eigenvectors of A (as columns)
         complex(qp),optional,intent(out),target :: left(:,:)
         !> [optional] Can A data be overwritten and destroyed? (default: no)
         logical(lk),optional,intent(in) :: overwrite_a
         !> [optional] Can B data be overwritten and destroyed? (default: no)
         logical(lk),optional,intent(in) :: overwrite_b
         !> [optional] state return flag. On error if not requested, the code will stop
         type(la_state),optional,intent(out) :: err

         !> Local variables
         type(la_state) :: err0
         integer(ilp) :: m,n,lda,ldu,ldv,info,k,lwork,neig,ldb,nb
         logical(lk) :: copy_a,copy_b
         character :: task_u,task_v
         complex(qp),target :: work_dummy(1),u_dummy(1,1),v_dummy(1,1)
         complex(qp),allocatable :: work(:)
         complex(qp),dimension(:,:),pointer :: amat,umat,vmat,bmat
         real(qp),allocatable :: rwork(:)
         complex(qp),allocatable :: beta(:)
         
         !> Matrix size
         m = size(a,1,kind=ilp)
         n = size(a,2,kind=ilp)
         k = min(m,n)
         neig = size(lambda,kind=ilp)
         lda = m

         if (k <= 0 .or. m /= n) then
            err0 = la_state(this,LINALG_VALUE_ERROR, &
                                          'invalid or matrix size a=', [m,n],', must be nonempty square.')
            call err0%handle(err)
            return
         elseif (neig < k) then
            err0 = la_state(this,LINALG_VALUE_ERROR, &
                                          'eigenvalue array has insufficient size:', &
                                          ' lambda=',neig,', n=',n)
            call err0%handle(err)
            return
         end if
         
         ldb = size(b,1,kind=ilp)
         nb = size(b,2,kind=ilp)
         if (ldb /= n .or. nb /= n) then
            err0 = la_state(this,LINALG_VALUE_ERROR, &
                                          'invalid or matrix size b=', [ldb,nb],', must be same as a=', [m,n])
            call err0%handle(err)
            return
         end if

         ! Can A be overwritten? By default, do not overwrite
         copy_a = .true._lk
         if (present(overwrite_a)) copy_a = .not. overwrite_a
         
         ! Initialize a matrix temporary
         if (copy_a) then
            allocate (amat(m,n),source=a)
         else
            amat => a
         end if

         ! Can B be overwritten? By default, do not overwrite
         copy_b = .true._lk
         if (present(overwrite_b)) copy_b = .not. overwrite_b
         
         ! Initialize a matrix temporary
         if (copy_b) then
            allocate (bmat,source=b)
         else
            bmat => b
         end if
         allocate (beta(n))

         ! Decide if U, V eigenvectors
         task_u = eigenvectors_task(present(left))
         task_v = eigenvectors_task(present(right))
         
         if (present(right)) then
                        
            ! For a complex matrix, GEEV returns complex arrays.
            ! Point directly to output.
            vmat => right
            
            if (size(vmat,2,kind=ilp) < n) then
               err0 = la_state(this,LINALG_VALUE_ERROR, &
                                        'right eigenvector matrix has insufficient size: ', &
                                        shape(vmat),', with n=',n)
            end if
            
         else
            vmat => v_dummy
         end if
            
         if (present(left)) then
            
            ! For a complex matrix, GEEV returns complex arrays.
            ! Point directly to output.
            umat => left

            if (size(umat,2,kind=ilp) < n) then
               err0 = la_state(this,LINALG_VALUE_ERROR, &
                                        'left eigenvector matrix has insufficient size: ', &
                                        shape(umat),', with n=',n)
            end if
            
         else
            umat => u_dummy
         end if
         
         get_ggev: if (err0%ok()) then

             ldu = size(umat,1,kind=ilp)
             ldv = size(vmat,1,kind=ilp)

             ! Compute workspace size
             allocate (rwork(8*n))
             
             lwork = -1_ilp
            
             call ggev(task_u,task_v,n,amat,lda, &
                       bmat,ldb, &
                       lambda, &
                       beta, &
                       umat,ldu,vmat,ldv, &
                       work_dummy,lwork,rwork,info)
             call handle_ggev_info(err0,info,shape(amat),shape(bmat))

             ! Compute eigenvalues
             if (info == 0) then

                !> Prepare working storage
                lwork = nint(real(work_dummy(1),kind=qp),kind=ilp)
                allocate (work(lwork))

                !> Compute eigensystem
                call ggev(task_u,task_v,n,amat,lda, &
                          bmat,ldb, &
                          lambda, &
                          beta, &
                          umat,ldu,vmat,ldv, &
                          work,lwork,rwork,info)
                call handle_ggev_info(err0,info,shape(amat),shape(bmat))

             end if
             
             ! Finalize storage and process output flag
             
             ! Scale generalized eigenvalues
             lambda(:n) = scale_general_eig(lambda(:n),beta)
             
         end if get_ggev
         
         if (copy_a) deallocate (amat)
         if (copy_b) deallocate (bmat)
         call err0%handle(err)

     end subroutine la_eig_generalized_w
     
     !> Return an array of eigenvalues of real symmetric / complex hermitian A
     function la_eigvalsh_w(a,upper_a,err) result(lambda)
         !> Input matrix A[m,n]
         complex(qp),intent(in),target :: a(:,:)
         !> [optional] Should the upper/lower half of A be used? Default: lower
         logical(lk),optional,intent(in) :: upper_a
         !> [optional] state return flag. On error if not requested, the code will stop
         type(la_state),intent(out) :: err
         !> Array of singular values
         real(qp),allocatable :: lambda(:)
         
         complex(qp),pointer :: amat(:,:)
         integer(ilp) :: m,n,k

         !> Create an internal pointer so the intent of A won't affect the next call
         amat => a

         m = size(a,1,kind=ilp)
         n = size(a,2,kind=ilp)
         k = min(m,n)

         !> Allocate return storage
         allocate (lambda(k))

         !> Compute eigenvalues only
         call la_eigh_w(amat,lambda,upper_a=upper_a,overwrite_a=.false.,err=err)
         
     end function la_eigvalsh_w
     
     !> Return an array of eigenvalues of real symmetric / complex hermitian A
     function la_eigvalsh_noerr_w(a,upper_a) result(lambda)
         !> Input matrix A[m,n]
         complex(qp),intent(in),target :: a(:,:)
         !> [optional] Should the upper/lower half of A be used? Default: lower
         logical(lk),optional,intent(in) :: upper_a
         !> Array of singular values
         real(qp),allocatable :: lambda(:)

         complex(qp),pointer :: amat(:,:)
         integer(ilp) :: m,n,k

         !> Create an internal pointer so the intent of A won't affect the next call
         amat => a

         m = size(a,1,kind=ilp)
         n = size(a,2,kind=ilp)
         k = min(m,n)

         !> Allocate return storage
         allocate (lambda(k))

         !> Compute eigenvalues only
         call la_eigh_w(amat,lambda,upper_a=upper_a,overwrite_a=.false.)

     end function la_eigvalsh_noerr_w

     !> Eigendecomposition of a real symmetric or complex Hermitian matrix A returning an array `lambda`
     !> of eigenvalues, and optionally right or left eigenvectors.
     subroutine la_eigh_w(a,lambda,vectors,upper_a,overwrite_a,err)
         !> Input matrix A[m,n]
         complex(qp),intent(inout),target :: a(:,:)
         !> Array of eigenvalues
         real(qp),intent(out) :: lambda(:)
         !> The columns of vectors contain the orthonormal eigenvectors of A
         complex(qp),optional,intent(out),target :: vectors(:,:)
         !> [optional] Can A data be overwritten and destroyed?
         logical(lk),optional,intent(in) :: overwrite_a
         !> [optional] Should the upper/lower half of A be used? Default: lower
         logical(lk),optional,intent(in) :: upper_a
         !> [optional] state return flag. On error if not requested, the code will stop
         type(la_state),optional,intent(out) :: err

         !> Local variables
         type(la_state) :: err0
         integer(ilp) :: m,n,lda,info,k,lwork,neig
         logical(lk) :: copy_a
         character :: triangle,task
         complex(qp),target :: work_dummy(1)
         complex(qp),allocatable :: work(:)
         real(qp),allocatable :: rwork(:)
         complex(qp),pointer :: amat(:,:)

         !> Matrix size
         m = size(a,1,kind=ilp)
         n = size(a,2,kind=ilp)
         k = min(m,n)
         neig = size(lambda,kind=ilp)

         if (.not. (k > 0 .and. m == n)) then
            err0 = la_state(this,LINALG_VALUE_ERROR,'invalid or matrix size a=', [m,n], &
                                                        ', must be square.')
            call err0%handle(err)
            return
         end if

         if (.not. neig >= k) then
            err0 = la_state(this,LINALG_VALUE_ERROR,'eigenvalue array has insufficient size:', &
                                                        ' lambda=',neig,' must be >= n=',n)
            call err0%handle(err)
            return
         end if
        
         ! Check if input A can be overwritten
         if (present(vectors)) then
            ! No need to copy A anyways
            copy_a = .false.
         elseif (present(overwrite_a)) then
            copy_a = .not. overwrite_a
         else
            copy_a = .true._lk
         end if
         
         ! Should we use the upper or lower half of the matrix?
         triangle = symmetric_triangle_task(upper_a)
         
         ! Request for eigenvectors
         task = eigenvectors_task(present(vectors))
         
         if (present(vectors)) then
            
            ! Check size
            if (any(shape(vectors,kind=ilp) < n)) then
               err0 = la_state(this,LINALG_VALUE_ERROR, &
                                        'eigenvector matrix has insufficient size: ', &
                                        shape(vectors),', with n=',n)
               call err0%handle(err)
               return
            end if
            
            ! The input matrix will be overwritten by the vectors.
            ! So, use this one as storage for syev/heev
            amat => vectors
            
            ! Copy data in
            amat(:n,:n) = a(:n,:n)
                        
         elseif (copy_a) then
            ! Initialize a matrix temporary
            allocate (amat(m,n),source=a)
         else
            ! Overwrite A
            amat => a
         end if

         lda = size(amat,1,kind=ilp)

         ! Request workspace size
         lwork = -1_ilp
         allocate (rwork(max(1,3*n - 2)))
         call heev(task,triangle,n,amat,lda,lambda,work_dummy,lwork,rwork,info)
         call heev_info(err0,info,m,n)

         ! Compute eigenvalues
         if (info == 0) then

            !> Prepare working storage
            lwork = nint(real(work_dummy(1),kind=qp),kind=ilp)
            allocate (work(lwork))

            !> Compute eigensystem
            call heev(task,triangle,n,amat,lda,lambda,work,lwork,rwork,info)
            call heev_info(err0,info,m,n)

         end if
         
         ! Finalize storage and process output flag
         if (copy_a) deallocate (amat)
         call err0%handle(err)

     end subroutine la_eigh_w
     
     !> GEEV for real matrices returns complex eigenvalues in real arrays.
     !> Convert them to complex here, following the GEEV logic.
     pure subroutine assign_real_eigenvectors_sp(n,lambda,lmat,out_mat)
        !> Problem size
        integer(ilp),intent(in) :: n
        !> Array of eigenvalues
        complex(sp),intent(in) :: lambda(:)
        !> Real matrix as returned by geev
        real(sp),intent(in) :: lmat(:,:)
        !> Complex matrix as returned by eig
        complex(sp),intent(out) :: out_mat(:,:)
        
        integer(ilp) :: i,j
        
        ! Copy matrix
        do concurrent(i=1:n,j=1:n)
           out_mat(i,j) = lmat(i,j)
        end do
        
        ! If the j-th and (j+1)-st eigenvalues form a complex conjugate pair,
        ! geev returns them as reals as:
        ! u(j)   = VL(:,j) + i*VL(:,j+1) and
        ! u(j+1) = VL(:,j) - i*VL(:,j+1).
        ! Convert these to complex numbers here.
        do j = 1,n - 1
           if (lambda(j) == conjg(lambda(j + 1))) then
              out_mat(:,j) = cmplx(lmat(:,j),lmat(:,j + 1),kind=sp)
              out_mat(:,j + 1) = cmplx(lmat(:,j),-lmat(:,j + 1),kind=sp)
           end if
        end do
        
     end subroutine assign_real_eigenvectors_sp
     
     subroutine la_real_eig_standard_s(a,lambda,right,left, &
                                                            overwrite_a,err)
      !! Eigendecomposition of matrix A returning an array `lambda` of real eigenvalues,
      !! and optionally right or left eigenvectors. Returns an error if the eigenvalues had
      !! non-trivial imaginary parts.
          !> Input matrix A[m,n]
          real(sp),intent(inout),target :: a(:,:)
          !> Array of real eigenvalues
          real(sp),intent(out) :: lambda(:)
          !> The columns of RIGHT contain the right eigenvectors of A
          complex(sp),optional,intent(out),target :: right(:,:)
          !> The columns of LEFT contain the left eigenvectors of A
          complex(sp),optional,intent(out),target :: left(:,:)
          !> [optional] Can A data be overwritten and destroyed?
          logical(lk),optional,intent(in) :: overwrite_a
          !> [optional] state return flag. On error if not requested, the code will stop
          type(la_state),optional,intent(out) :: err
          
          type(la_state) :: err0
          integer(ilp) :: n
          complex(sp),allocatable :: clambda(:)
          real(sp),parameter :: rtol = epsilon(0.0_sp)
          real(sp),parameter :: atol = tiny(0.0_sp)
          
          n = size(lambda,dim=1,kind=ilp)
          allocate (clambda(n))
          
          call la_eig_standard_s(a,clambda,right,left, &
                                                 overwrite_a,err0)
          
          ! Check that no eigenvalues have meaningful imaginary part
          if (err0%ok() .and. any(aimag(clambda) > atol + rtol*abs(abs(clambda)))) then
             err0 = la_state(this,LINALG_VALUE_ERROR, &
                             'complex eigenvalues detected: max(imag(lambda))=',maxval(aimag(clambda)))
          end if
          
          ! Return real components only
          lambda(:n) = real(clambda,kind=sp)
          
          call err0%handle(err)
          
     end subroutine la_real_eig_standard_s
     
     subroutine la_real_eig_generalized_s(a,b,lambda,right,left, &
                                                            overwrite_a,overwrite_b,err)
      !! Eigendecomposition of matrix A returning an array `lambda` of real eigenvalues,
      !! and optionally right or left eigenvectors. Returns an error if the eigenvalues had
      !! non-trivial imaginary parts.
          !> Input matrix A[m,n]
          real(sp),intent(inout),target :: a(:,:)
          !> Generalized problem matrix B[n,n]
          real(sp),intent(inout),target :: b(:,:)
          !> Array of real eigenvalues
          real(sp),intent(out) :: lambda(:)
          !> The columns of RIGHT contain the right eigenvectors of A
          complex(sp),optional,intent(out),target :: right(:,:)
          !> The columns of LEFT contain the left eigenvectors of A
          complex(sp),optional,intent(out),target :: left(:,:)
          !> [optional] Can A data be overwritten and destroyed?
          logical(lk),optional,intent(in) :: overwrite_a
          !> [optional] Can B data be overwritten and destroyed? (default: no)
          logical(lk),optional,intent(in) :: overwrite_b
          !> [optional] state return flag. On error if not requested, the code will stop
          type(la_state),optional,intent(out) :: err
          
          type(la_state) :: err0
          integer(ilp) :: n
          complex(sp),allocatable :: clambda(:)
          real(sp),parameter :: rtol = epsilon(0.0_sp)
          real(sp),parameter :: atol = tiny(0.0_sp)
          
          n = size(lambda,dim=1,kind=ilp)
          allocate (clambda(n))
          
          call la_eig_generalized_s(a,b,clambda,right,left, &
                                                 overwrite_a,overwrite_b,err0)
          
          ! Check that no eigenvalues have meaningful imaginary part
          if (err0%ok() .and. any(aimag(clambda) > atol + rtol*abs(abs(clambda)))) then
             err0 = la_state(this,LINALG_VALUE_ERROR, &
                             'complex eigenvalues detected: max(imag(lambda))=',maxval(aimag(clambda)))
          end if
          
          ! Return real components only
          lambda(:n) = real(clambda,kind=sp)
          
          call err0%handle(err)
          
     end subroutine la_real_eig_generalized_s
     
     !> GEEV for real matrices returns complex eigenvalues in real arrays.
     !> Convert them to complex here, following the GEEV logic.
     pure subroutine assign_real_eigenvectors_dp(n,lambda,lmat,out_mat)
        !> Problem size
        integer(ilp),intent(in) :: n
        !> Array of eigenvalues
        complex(dp),intent(in) :: lambda(:)
        !> Real matrix as returned by geev
        real(dp),intent(in) :: lmat(:,:)
        !> Complex matrix as returned by eig
        complex(dp),intent(out) :: out_mat(:,:)
        
        integer(ilp) :: i,j
        
        ! Copy matrix
        do concurrent(i=1:n,j=1:n)
           out_mat(i,j) = lmat(i,j)
        end do
        
        ! If the j-th and (j+1)-st eigenvalues form a complex conjugate pair,
        ! geev returns them as reals as:
        ! u(j)   = VL(:,j) + i*VL(:,j+1) and
        ! u(j+1) = VL(:,j) - i*VL(:,j+1).
        ! Convert these to complex numbers here.
        do j = 1,n - 1
           if (lambda(j) == conjg(lambda(j + 1))) then
              out_mat(:,j) = cmplx(lmat(:,j),lmat(:,j + 1),kind=dp)
              out_mat(:,j + 1) = cmplx(lmat(:,j),-lmat(:,j + 1),kind=dp)
           end if
        end do
        
     end subroutine assign_real_eigenvectors_dp
     
     subroutine la_real_eig_standard_d(a,lambda,right,left, &
                                                            overwrite_a,err)
      !! Eigendecomposition of matrix A returning an array `lambda` of real eigenvalues,
      !! and optionally right or left eigenvectors. Returns an error if the eigenvalues had
      !! non-trivial imaginary parts.
          !> Input matrix A[m,n]
          real(dp),intent(inout),target :: a(:,:)
          !> Array of real eigenvalues
          real(dp),intent(out) :: lambda(:)
          !> The columns of RIGHT contain the right eigenvectors of A
          complex(dp),optional,intent(out),target :: right(:,:)
          !> The columns of LEFT contain the left eigenvectors of A
          complex(dp),optional,intent(out),target :: left(:,:)
          !> [optional] Can A data be overwritten and destroyed?
          logical(lk),optional,intent(in) :: overwrite_a
          !> [optional] state return flag. On error if not requested, the code will stop
          type(la_state),optional,intent(out) :: err
          
          type(la_state) :: err0
          integer(ilp) :: n
          complex(dp),allocatable :: clambda(:)
          real(dp),parameter :: rtol = epsilon(0.0_dp)
          real(dp),parameter :: atol = tiny(0.0_dp)
          
          n = size(lambda,dim=1,kind=ilp)
          allocate (clambda(n))
          
          call la_eig_standard_d(a,clambda,right,left, &
                                                 overwrite_a,err0)
          
          ! Check that no eigenvalues have meaningful imaginary part
          if (err0%ok() .and. any(aimag(clambda) > atol + rtol*abs(abs(clambda)))) then
             err0 = la_state(this,LINALG_VALUE_ERROR, &
                             'complex eigenvalues detected: max(imag(lambda))=',maxval(aimag(clambda)))
          end if
          
          ! Return real components only
          lambda(:n) = real(clambda,kind=dp)
          
          call err0%handle(err)
          
     end subroutine la_real_eig_standard_d
     
     subroutine la_real_eig_generalized_d(a,b,lambda,right,left, &
                                                            overwrite_a,overwrite_b,err)
      !! Eigendecomposition of matrix A returning an array `lambda` of real eigenvalues,
      !! and optionally right or left eigenvectors. Returns an error if the eigenvalues had
      !! non-trivial imaginary parts.
          !> Input matrix A[m,n]
          real(dp),intent(inout),target :: a(:,:)
          !> Generalized problem matrix B[n,n]
          real(dp),intent(inout),target :: b(:,:)
          !> Array of real eigenvalues
          real(dp),intent(out) :: lambda(:)
          !> The columns of RIGHT contain the right eigenvectors of A
          complex(dp),optional,intent(out),target :: right(:,:)
          !> The columns of LEFT contain the left eigenvectors of A
          complex(dp),optional,intent(out),target :: left(:,:)
          !> [optional] Can A data be overwritten and destroyed?
          logical(lk),optional,intent(in) :: overwrite_a
          !> [optional] Can B data be overwritten and destroyed? (default: no)
          logical(lk),optional,intent(in) :: overwrite_b
          !> [optional] state return flag. On error if not requested, the code will stop
          type(la_state),optional,intent(out) :: err
          
          type(la_state) :: err0
          integer(ilp) :: n
          complex(dp),allocatable :: clambda(:)
          real(dp),parameter :: rtol = epsilon(0.0_dp)
          real(dp),parameter :: atol = tiny(0.0_dp)
          
          n = size(lambda,dim=1,kind=ilp)
          allocate (clambda(n))
          
          call la_eig_generalized_d(a,b,clambda,right,left, &
                                                 overwrite_a,overwrite_b,err0)
          
          ! Check that no eigenvalues have meaningful imaginary part
          if (err0%ok() .and. any(aimag(clambda) > atol + rtol*abs(abs(clambda)))) then
             err0 = la_state(this,LINALG_VALUE_ERROR, &
                             'complex eigenvalues detected: max(imag(lambda))=',maxval(aimag(clambda)))
          end if
          
          ! Return real components only
          lambda(:n) = real(clambda,kind=dp)
          
          call err0%handle(err)
          
     end subroutine la_real_eig_generalized_d
     
     !> GEEV for real matrices returns complex eigenvalues in real arrays.
     !> Convert them to complex here, following the GEEV logic.
     pure subroutine assign_real_eigenvectors_qp(n,lambda,lmat,out_mat)
        !> Problem size
        integer(ilp),intent(in) :: n
        !> Array of eigenvalues
        complex(qp),intent(in) :: lambda(:)
        !> Real matrix as returned by geev
        real(qp),intent(in) :: lmat(:,:)
        !> Complex matrix as returned by eig
        complex(qp),intent(out) :: out_mat(:,:)
        
        integer(ilp) :: i,j
        
        ! Copy matrix
        do concurrent(i=1:n,j=1:n)
           out_mat(i,j) = lmat(i,j)
        end do
        
        ! If the j-th and (j+1)-st eigenvalues form a complex conjugate pair,
        ! geev returns them as reals as:
        ! u(j)   = VL(:,j) + i*VL(:,j+1) and
        ! u(j+1) = VL(:,j) - i*VL(:,j+1).
        ! Convert these to complex numbers here.
        do j = 1,n - 1
           if (lambda(j) == conjg(lambda(j + 1))) then
              out_mat(:,j) = cmplx(lmat(:,j),lmat(:,j + 1),kind=qp)
              out_mat(:,j + 1) = cmplx(lmat(:,j),-lmat(:,j + 1),kind=qp)
           end if
        end do
        
     end subroutine assign_real_eigenvectors_qp
     
     subroutine la_real_eig_standard_q(a,lambda,right,left, &
                                                            overwrite_a,err)
      !! Eigendecomposition of matrix A returning an array `lambda` of real eigenvalues,
      !! and optionally right or left eigenvectors. Returns an error if the eigenvalues had
      !! non-trivial imaginary parts.
          !> Input matrix A[m,n]
          real(qp),intent(inout),target :: a(:,:)
          !> Array of real eigenvalues
          real(qp),intent(out) :: lambda(:)
          !> The columns of RIGHT contain the right eigenvectors of A
          complex(qp),optional,intent(out),target :: right(:,:)
          !> The columns of LEFT contain the left eigenvectors of A
          complex(qp),optional,intent(out),target :: left(:,:)
          !> [optional] Can A data be overwritten and destroyed?
          logical(lk),optional,intent(in) :: overwrite_a
          !> [optional] state return flag. On error if not requested, the code will stop
          type(la_state),optional,intent(out) :: err
          
          type(la_state) :: err0
          integer(ilp) :: n
          complex(qp),allocatable :: clambda(:)
          real(qp),parameter :: rtol = epsilon(0.0_qp)
          real(qp),parameter :: atol = tiny(0.0_qp)
          
          n = size(lambda,dim=1,kind=ilp)
          allocate (clambda(n))
          
          call la_eig_standard_q(a,clambda,right,left, &
                                                 overwrite_a,err0)
          
          ! Check that no eigenvalues have meaningful imaginary part
          if (err0%ok() .and. any(aimag(clambda) > atol + rtol*abs(abs(clambda)))) then
             err0 = la_state(this,LINALG_VALUE_ERROR, &
                             'complex eigenvalues detected: max(imag(lambda))=',maxval(aimag(clambda)))
          end if
          
          ! Return real components only
          lambda(:n) = real(clambda,kind=qp)
          
          call err0%handle(err)
          
     end subroutine la_real_eig_standard_q
     
     subroutine la_real_eig_generalized_q(a,b,lambda,right,left, &
                                                            overwrite_a,overwrite_b,err)
      !! Eigendecomposition of matrix A returning an array `lambda` of real eigenvalues,
      !! and optionally right or left eigenvectors. Returns an error if the eigenvalues had
      !! non-trivial imaginary parts.
          !> Input matrix A[m,n]
          real(qp),intent(inout),target :: a(:,:)
          !> Generalized problem matrix B[n,n]
          real(qp),intent(inout),target :: b(:,:)
          !> Array of real eigenvalues
          real(qp),intent(out) :: lambda(:)
          !> The columns of RIGHT contain the right eigenvectors of A
          complex(qp),optional,intent(out),target :: right(:,:)
          !> The columns of LEFT contain the left eigenvectors of A
          complex(qp),optional,intent(out),target :: left(:,:)
          !> [optional] Can A data be overwritten and destroyed?
          logical(lk),optional,intent(in) :: overwrite_a
          !> [optional] Can B data be overwritten and destroyed? (default: no)
          logical(lk),optional,intent(in) :: overwrite_b
          !> [optional] state return flag. On error if not requested, the code will stop
          type(la_state),optional,intent(out) :: err
          
          type(la_state) :: err0
          integer(ilp) :: n
          complex(qp),allocatable :: clambda(:)
          real(qp),parameter :: rtol = epsilon(0.0_qp)
          real(qp),parameter :: atol = tiny(0.0_qp)
          
          n = size(lambda,dim=1,kind=ilp)
          allocate (clambda(n))
          
          call la_eig_generalized_q(a,b,clambda,right,left, &
                                                 overwrite_a,overwrite_b,err0)
          
          ! Check that no eigenvalues have meaningful imaginary part
          if (err0%ok() .and. any(aimag(clambda) > atol + rtol*abs(abs(clambda)))) then
             err0 = la_state(this,LINALG_VALUE_ERROR, &
                             'complex eigenvalues detected: max(imag(lambda))=',maxval(aimag(clambda)))
          end if
          
          ! Return real components only
          lambda(:n) = real(clambda,kind=qp)
          
          call err0%handle(err)
          
     end subroutine la_real_eig_generalized_q
     
     !> Utility function: Scale generalized eigenvalue
     elemental complex(sp) function scale_general_eig_s(alpha,beta) result(lambda)
         !! A generalized eigenvalue for a pair of matrices (A,B) is a scalar lambda or a ratio
         !! alpha/beta = lambda, such that A - lambda*B is singular. It is usually represented as the
         !! pair (alpha,beta), there is a reasonable interpretation for beta=0, and even for both
         !! being zero.
         complex(sp),intent(in) :: alpha
         real(sp),intent(in) :: beta
         
         real(sp),parameter :: rzero = 0.0_sp
         complex(sp),parameter :: czero = (0.0_sp,0.0_sp)
         
         if (beta == rzero) then
            if (alpha /= czero) then
                lambda = cmplx(ieee_value(1.0_sp,ieee_positive_inf), &
                               ieee_value(1.0_sp,ieee_positive_inf),kind=sp)
            else
                lambda = ieee_value(1.0_sp,ieee_quiet_nan)
            end if
         else
            lambda = alpha/beta
         end if
         
     end function scale_general_eig_s
     
     !> Utility function: Scale generalized eigenvalue
     elemental complex(dp) function scale_general_eig_d(alpha,beta) result(lambda)
         !! A generalized eigenvalue for a pair of matrices (A,B) is a scalar lambda or a ratio
         !! alpha/beta = lambda, such that A - lambda*B is singular. It is usually represented as the
         !! pair (alpha,beta), there is a reasonable interpretation for beta=0, and even for both
         !! being zero.
         complex(dp),intent(in) :: alpha
         real(dp),intent(in) :: beta
         
         real(dp),parameter :: rzero = 0.0_dp
         complex(dp),parameter :: czero = (0.0_dp,0.0_dp)
         
         if (beta == rzero) then
            if (alpha /= czero) then
                lambda = cmplx(ieee_value(1.0_dp,ieee_positive_inf), &
                               ieee_value(1.0_dp,ieee_positive_inf),kind=dp)
            else
                lambda = ieee_value(1.0_dp,ieee_quiet_nan)
            end if
         else
            lambda = alpha/beta
         end if
         
     end function scale_general_eig_d
     
     !> Utility function: Scale generalized eigenvalue
     elemental complex(qp) function scale_general_eig_q(alpha,beta) result(lambda)
         !! A generalized eigenvalue for a pair of matrices (A,B) is a scalar lambda or a ratio
         !! alpha/beta = lambda, such that A - lambda*B is singular. It is usually represented as the
         !! pair (alpha,beta), there is a reasonable interpretation for beta=0, and even for both
         !! being zero.
         complex(qp),intent(in) :: alpha
         real(qp),intent(in) :: beta
         
         real(qp),parameter :: rzero = 0.0_qp
         complex(qp),parameter :: czero = (0.0_qp,0.0_qp)
         
         if (beta == rzero) then
            if (alpha /= czero) then
                lambda = cmplx(ieee_value(1.0_qp,ieee_positive_inf), &
                               ieee_value(1.0_qp,ieee_positive_inf),kind=qp)
            else
                lambda = ieee_value(1.0_qp,ieee_quiet_nan)
            end if
         else
            lambda = alpha/beta
         end if
         
     end function scale_general_eig_q
     
     !> Utility function: Scale generalized eigenvalue
     elemental complex(sp) function scale_general_eig_c(alpha,beta) result(lambda)
         !! A generalized eigenvalue for a pair of matrices (A,B) is a scalar lambda or a ratio
         !! alpha/beta = lambda, such that A - lambda*B is singular. It is usually represented as the
         !! pair (alpha,beta), there is a reasonable interpretation for beta=0, and even for both
         !! being zero.
         complex(sp),intent(in) :: alpha
         complex(sp),intent(in) :: beta
         
         real(sp),parameter :: rzero = 0.0_sp
         complex(sp),parameter :: czero = (0.0_sp,0.0_sp)
         
         if (beta == czero) then
            if (alpha /= czero) then
                lambda = cmplx(ieee_value(1.0_sp,ieee_positive_inf), &
                               ieee_value(1.0_sp,ieee_positive_inf),kind=sp)
            else
                lambda = ieee_value(1.0_sp,ieee_quiet_nan)
            end if
         else
            lambda = alpha/beta
         end if
         
     end function scale_general_eig_c
     
     !> Utility function: Scale generalized eigenvalue
     elemental complex(dp) function scale_general_eig_z(alpha,beta) result(lambda)
         !! A generalized eigenvalue for a pair of matrices (A,B) is a scalar lambda or a ratio
         !! alpha/beta = lambda, such that A - lambda*B is singular. It is usually represented as the
         !! pair (alpha,beta), there is a reasonable interpretation for beta=0, and even for both
         !! being zero.
         complex(dp),intent(in) :: alpha
         complex(dp),intent(in) :: beta
         
         real(dp),parameter :: rzero = 0.0_dp
         complex(dp),parameter :: czero = (0.0_dp,0.0_dp)
         
         if (beta == czero) then
            if (alpha /= czero) then
                lambda = cmplx(ieee_value(1.0_dp,ieee_positive_inf), &
                               ieee_value(1.0_dp,ieee_positive_inf),kind=dp)
            else
                lambda = ieee_value(1.0_dp,ieee_quiet_nan)
            end if
         else
            lambda = alpha/beta
         end if
         
     end function scale_general_eig_z
     
     !> Utility function: Scale generalized eigenvalue
     elemental complex(qp) function scale_general_eig_w(alpha,beta) result(lambda)
         !! A generalized eigenvalue for a pair of matrices (A,B) is a scalar lambda or a ratio
         !! alpha/beta = lambda, such that A - lambda*B is singular. It is usually represented as the
         !! pair (alpha,beta), there is a reasonable interpretation for beta=0, and even for both
         !! being zero.
         complex(qp),intent(in) :: alpha
         complex(qp),intent(in) :: beta
         
         real(qp),parameter :: rzero = 0.0_qp
         complex(qp),parameter :: czero = (0.0_qp,0.0_qp)
         
         if (beta == czero) then
            if (alpha /= czero) then
                lambda = cmplx(ieee_value(1.0_qp,ieee_positive_inf), &
                               ieee_value(1.0_qp,ieee_positive_inf),kind=qp)
            else
                lambda = ieee_value(1.0_qp,ieee_quiet_nan)
            end if
         else
            lambda = alpha/beta
         end if
         
     end function scale_general_eig_w
     
end module la_eig
