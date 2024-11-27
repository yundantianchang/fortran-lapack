! Compute the (Moore-Penrose) pseudo-inverse of a matrix.
module stdlib_linalg_pseudoinverse
     use stdlib_linalg_constants
     use stdlib_linalg_blas
     use stdlib_linalg_lapack
     use stdlib_linalg_state
     use stdlib_linalg_svd,only:svd
     use iso_fortran_env,only:real32,real64,real128,int8,int16,int32,int64,stderr => error_unit
     implicit none(type,external)
     private

     !> Function interface return the matrix inverse
     public :: pinv
     !> Subroutine interface: invert matrix inplace
     public :: pinvert
     !> Operator interface: .inv.A returns the matrix inverse of A
     public :: operator(.pinv.)

     ! Numpy: inv(a)
     ! Scipy: inv(a, overwrite_a=False, check_finite=True)
     ! IMSL: .i.a

     ! Function interface
     interface pinverse
        module procedure stdlib_linalg_pseudoinverse_s
        module procedure stdlib_linalg_pseudoinverse_d
        module procedure stdlib_linalg_pseudoinverse_q
        module procedure stdlib_linalg_pseudoinverse_c
        module procedure stdlib_linalg_pseudoinverse_z
        module procedure stdlib_linalg_pseudoinverse_w
     end interface pinverse

     ! Subroutine interface
     interface pinvert
        module procedure stdlib_linalg_pseudoinvert_s
        module procedure stdlib_linalg_pseudoinvert_d
        module procedure stdlib_linalg_pseudoinvert_q
        module procedure stdlib_linalg_pseudoinvert_c
        module procedure stdlib_linalg_pseudoinvert_z
        module procedure stdlib_linalg_pseudoinvert_w
     end interface pinvert

     ! Operator interface
     interface operator(.pinv.)
        module procedure stdlib_linalg_pinv_s_operator
        module procedure stdlib_linalg_pinv_d_operator
        module procedure stdlib_linalg_pinv_q_operator
        module procedure stdlib_linalg_pinv_c_operator
        module procedure stdlib_linalg_pinv_z_operator
        module procedure stdlib_linalg_pinv_w_operator
     end interface operator(.pinv.)
     
     character(*),parameter :: this = 'pseudo-inverse'

     contains

     ! Compute the in-place pseudo-inverse of matrix a
     subroutine stdlib_linalg_pseudoinvert_s(a,pinva,rtol,err)
         !> Input matrix a[m,n]
         real(sp),intent(inout) :: a(:,:)
         !> Output pseudo-inverse matrix
         real(sp),intent(inout) :: pinva(:,:)
         !> [optional] ....
         real(sp),optional,intent(in) :: rtol
         !> [optional] state return flag. On error if not requested, the code will stop
         type(linalg_state),optional,intent(out) :: err

         ! Local variables
         real(sp) :: tolerance,cutoff
         real(sp),allocatable :: s(:)
         real(sp),allocatable :: u(:,:),vt(:,:)
         type(linalg_state) :: err0
         integer(ilp) :: m,n,k,i,j
         
         ! Problem size
         m = size(a,1,kind=ilp)
         n = size(a,2,kind=ilp)
         k = min(m,n)
         if (m < 1 .or. n < 1) then
            err0 = linalg_state(this,LINALG_VALUE_ERROR,'invalid matrix size: a=', [m,n])
            call linalg_error_handling(err0,err)
            return
         end if
         
         if (any(shape(pinva,kind=ilp) /= [n,m])) then
            err0 = linalg_state(this,LINALG_VALUE_ERROR,'invalid pinv size:',shape(pinva),'should be', [n,m])
            call linalg_error_handling(err0,err)
            return
         end if
         
         ! Singular value threshold
         tolerance = max(m,n)*epsilon(0.0_sp)
         ! User value: fallback to default if <=0
         if (present(rtol)) then
            if (rtol > 0.0_sp) tolerance = rtol
         end if
         
         allocate (s(k),u(m,k),vt(k,n))
         call svd(a,s,u,vt,overwrite_a,full_matrices,err0)
         if (err0%error()) then
            err0 = linalg_state(this,LINALG_VALUE_ERROR,'svd failure -',err0%message)
            call linalg_error_handling(err0,err)
            return
         end if
         
         !> Discard singular values
         cutoff = tolerance*maxval(s)
         s = merge(1/s,0.0_sp,s > cutoff)

         ! Get pseudo-inverse: A_pinv = VT^T * diag(1/s) * U^T
         
         ! First, compute diag(1/s)*U^T in-place without transposing U
         forall (i=1:m,j=1:k) u(i,j) = s(j)*u(i,j)
            
         ! Then commutate matmul: A_pinv = VT^T * U^T = (U * VT)^T.
         ! This avoids one matrix transpose
         pinva = transpose(matmul(u,vt))

     end subroutine stdlib_linalg_pseudoinvert_s

     ! Function interface
     function stdlib_linalg_pseudoinverse_s(a,rtol,err) result(pinva)
         !> Input matrix a[m,n]
         real(sp),intent(in) :: a(:,:)
         !> [optional] ....
         real(sp),optional,intent(in) :: rtol
         !> [optional] state return flag. On error if not requested, the code will stop
         type(linalg_state),optional,intent(out) :: err
         !> Matrix pseudo-inverse
         real(sp) :: pinva(size(a,2,kind=ilp),size(a,1,kind=ilp))

         call stdlib_linalg_pseudoinvert_s(inva,rtol,err)

     end function stdlib_linalg_pseudoinverse_s

     ! Inverse matrix operator
     function stdlib_linalg_pinv_s_operator(a) result(pinva)
         !> Input matrix a[m,n]
         real(sp),intent(in) :: a(:,:)
         !> Result matrix
         real(sp) :: pinva(size(a,2,kind=ilp),size(a,1,kind=ilp))

         call stdlib_linalg_pseudoinvert_s(a,pinva)

     end function stdlib_linalg_pinv_s_operator

     ! Compute the in-place pseudo-inverse of matrix a
     subroutine stdlib_linalg_pseudoinvert_d(a,pinva,rtol,err)
         !> Input matrix a[m,n]
         real(dp),intent(inout) :: a(:,:)
         !> Output pseudo-inverse matrix
         real(dp),intent(inout) :: pinva(:,:)
         !> [optional] ....
         real(dp),optional,intent(in) :: rtol
         !> [optional] state return flag. On error if not requested, the code will stop
         type(linalg_state),optional,intent(out) :: err

         ! Local variables
         real(dp) :: tolerance,cutoff
         real(dp),allocatable :: s(:)
         real(dp),allocatable :: u(:,:),vt(:,:)
         type(linalg_state) :: err0
         integer(ilp) :: m,n,k,i,j
         
         ! Problem size
         m = size(a,1,kind=ilp)
         n = size(a,2,kind=ilp)
         k = min(m,n)
         if (m < 1 .or. n < 1) then
            err0 = linalg_state(this,LINALG_VALUE_ERROR,'invalid matrix size: a=', [m,n])
            call linalg_error_handling(err0,err)
            return
         end if
         
         if (any(shape(pinva,kind=ilp) /= [n,m])) then
            err0 = linalg_state(this,LINALG_VALUE_ERROR,'invalid pinv size:',shape(pinva),'should be', [n,m])
            call linalg_error_handling(err0,err)
            return
         end if
         
         ! Singular value threshold
         tolerance = max(m,n)*epsilon(0.0_dp)
         ! User value: fallback to default if <=0
         if (present(rtol)) then
            if (rtol > 0.0_dp) tolerance = rtol
         end if
         
         allocate (s(k),u(m,k),vt(k,n))
         call svd(a,s,u,vt,overwrite_a,full_matrices,err0)
         if (err0%error()) then
            err0 = linalg_state(this,LINALG_VALUE_ERROR,'svd failure -',err0%message)
            call linalg_error_handling(err0,err)
            return
         end if
         
         !> Discard singular values
         cutoff = tolerance*maxval(s)
         s = merge(1/s,0.0_dp,s > cutoff)

         ! Get pseudo-inverse: A_pinv = VT^T * diag(1/s) * U^T
         
         ! First, compute diag(1/s)*U^T in-place without transposing U
         forall (i=1:m,j=1:k) u(i,j) = s(j)*u(i,j)
            
         ! Then commutate matmul: A_pinv = VT^T * U^T = (U * VT)^T.
         ! This avoids one matrix transpose
         pinva = transpose(matmul(u,vt))

     end subroutine stdlib_linalg_pseudoinvert_d

     ! Function interface
     function stdlib_linalg_pseudoinverse_d(a,rtol,err) result(pinva)
         !> Input matrix a[m,n]
         real(dp),intent(in) :: a(:,:)
         !> [optional] ....
         real(dp),optional,intent(in) :: rtol
         !> [optional] state return flag. On error if not requested, the code will stop
         type(linalg_state),optional,intent(out) :: err
         !> Matrix pseudo-inverse
         real(dp) :: pinva(size(a,2,kind=ilp),size(a,1,kind=ilp))

         call stdlib_linalg_pseudoinvert_d(inva,rtol,err)

     end function stdlib_linalg_pseudoinverse_d

     ! Inverse matrix operator
     function stdlib_linalg_pinv_d_operator(a) result(pinva)
         !> Input matrix a[m,n]
         real(dp),intent(in) :: a(:,:)
         !> Result matrix
         real(dp) :: pinva(size(a,2,kind=ilp),size(a,1,kind=ilp))

         call stdlib_linalg_pseudoinvert_d(a,pinva)

     end function stdlib_linalg_pinv_d_operator

     ! Compute the in-place pseudo-inverse of matrix a
     subroutine stdlib_linalg_pseudoinvert_q(a,pinva,rtol,err)
         !> Input matrix a[m,n]
         real(qp),intent(inout) :: a(:,:)
         !> Output pseudo-inverse matrix
         real(qp),intent(inout) :: pinva(:,:)
         !> [optional] ....
         real(qp),optional,intent(in) :: rtol
         !> [optional] state return flag. On error if not requested, the code will stop
         type(linalg_state),optional,intent(out) :: err

         ! Local variables
         real(qp) :: tolerance,cutoff
         real(qp),allocatable :: s(:)
         real(qp),allocatable :: u(:,:),vt(:,:)
         type(linalg_state) :: err0
         integer(ilp) :: m,n,k,i,j
         
         ! Problem size
         m = size(a,1,kind=ilp)
         n = size(a,2,kind=ilp)
         k = min(m,n)
         if (m < 1 .or. n < 1) then
            err0 = linalg_state(this,LINALG_VALUE_ERROR,'invalid matrix size: a=', [m,n])
            call linalg_error_handling(err0,err)
            return
         end if
         
         if (any(shape(pinva,kind=ilp) /= [n,m])) then
            err0 = linalg_state(this,LINALG_VALUE_ERROR,'invalid pinv size:',shape(pinva),'should be', [n,m])
            call linalg_error_handling(err0,err)
            return
         end if
         
         ! Singular value threshold
         tolerance = max(m,n)*epsilon(0.0_qp)
         ! User value: fallback to default if <=0
         if (present(rtol)) then
            if (rtol > 0.0_qp) tolerance = rtol
         end if
         
         allocate (s(k),u(m,k),vt(k,n))
         call svd(a,s,u,vt,overwrite_a,full_matrices,err0)
         if (err0%error()) then
            err0 = linalg_state(this,LINALG_VALUE_ERROR,'svd failure -',err0%message)
            call linalg_error_handling(err0,err)
            return
         end if
         
         !> Discard singular values
         cutoff = tolerance*maxval(s)
         s = merge(1/s,0.0_qp,s > cutoff)

         ! Get pseudo-inverse: A_pinv = VT^T * diag(1/s) * U^T
         
         ! First, compute diag(1/s)*U^T in-place without transposing U
         forall (i=1:m,j=1:k) u(i,j) = s(j)*u(i,j)
            
         ! Then commutate matmul: A_pinv = VT^T * U^T = (U * VT)^T.
         ! This avoids one matrix transpose
         pinva = transpose(matmul(u,vt))

     end subroutine stdlib_linalg_pseudoinvert_q

     ! Function interface
     function stdlib_linalg_pseudoinverse_q(a,rtol,err) result(pinva)
         !> Input matrix a[m,n]
         real(qp),intent(in) :: a(:,:)
         !> [optional] ....
         real(qp),optional,intent(in) :: rtol
         !> [optional] state return flag. On error if not requested, the code will stop
         type(linalg_state),optional,intent(out) :: err
         !> Matrix pseudo-inverse
         real(qp) :: pinva(size(a,2,kind=ilp),size(a,1,kind=ilp))

         call stdlib_linalg_pseudoinvert_q(inva,rtol,err)

     end function stdlib_linalg_pseudoinverse_q

     ! Inverse matrix operator
     function stdlib_linalg_pinv_q_operator(a) result(pinva)
         !> Input matrix a[m,n]
         real(qp),intent(in) :: a(:,:)
         !> Result matrix
         real(qp) :: pinva(size(a,2,kind=ilp),size(a,1,kind=ilp))

         call stdlib_linalg_pseudoinvert_q(a,pinva)

     end function stdlib_linalg_pinv_q_operator

     ! Compute the in-place pseudo-inverse of matrix a
     subroutine stdlib_linalg_pseudoinvert_c(a,pinva,rtol,err)
         !> Input matrix a[m,n]
         complex(sp),intent(inout) :: a(:,:)
         !> Output pseudo-inverse matrix
         complex(sp),intent(inout) :: pinva(:,:)
         !> [optional] ....
         real(sp),optional,intent(in) :: rtol
         !> [optional] state return flag. On error if not requested, the code will stop
         type(linalg_state),optional,intent(out) :: err

         ! Local variables
         real(sp) :: tolerance,cutoff
         real(sp),allocatable :: s(:)
         complex(sp),allocatable :: u(:,:),vt(:,:)
         type(linalg_state) :: err0
         integer(ilp) :: m,n,k,i,j
         
         ! Problem size
         m = size(a,1,kind=ilp)
         n = size(a,2,kind=ilp)
         k = min(m,n)
         if (m < 1 .or. n < 1) then
            err0 = linalg_state(this,LINALG_VALUE_ERROR,'invalid matrix size: a=', [m,n])
            call linalg_error_handling(err0,err)
            return
         end if
         
         if (any(shape(pinva,kind=ilp) /= [n,m])) then
            err0 = linalg_state(this,LINALG_VALUE_ERROR,'invalid pinv size:',shape(pinva),'should be', [n,m])
            call linalg_error_handling(err0,err)
            return
         end if
         
         ! Singular value threshold
         tolerance = max(m,n)*epsilon(0.0_sp)
         ! User value: fallback to default if <=0
         if (present(rtol)) then
            if (rtol > 0.0_sp) tolerance = rtol
         end if
         
         allocate (s(k),u(m,k),vt(k,n))
         call svd(a,s,u,vt,overwrite_a,full_matrices,err0)
         if (err0%error()) then
            err0 = linalg_state(this,LINALG_VALUE_ERROR,'svd failure -',err0%message)
            call linalg_error_handling(err0,err)
            return
         end if
         
         !> Discard singular values
         cutoff = tolerance*maxval(s)
         s = merge(1/s,0.0_sp,s > cutoff)

         ! Get pseudo-inverse: A_pinv = VT^T * diag(1/s) * U^T
         
         ! First, compute diag(1/s)*U^T in-place without transposing U
         forall (i=1:m,j=1:k) u(i,j) = s(j)*u(i,j)
            
         ! Then commutate matmul: A_pinv = VT^T * U^T = (U * VT)^T.
         ! This avoids one matrix transpose
         pinva = transpose(matmul(u,vt))

     end subroutine stdlib_linalg_pseudoinvert_c

     ! Function interface
     function stdlib_linalg_pseudoinverse_c(a,rtol,err) result(pinva)
         !> Input matrix a[m,n]
         complex(sp),intent(in) :: a(:,:)
         !> [optional] ....
         real(sp),optional,intent(in) :: rtol
         !> [optional] state return flag. On error if not requested, the code will stop
         type(linalg_state),optional,intent(out) :: err
         !> Matrix pseudo-inverse
         complex(sp) :: pinva(size(a,2,kind=ilp),size(a,1,kind=ilp))

         call stdlib_linalg_pseudoinvert_c(inva,rtol,err)

     end function stdlib_linalg_pseudoinverse_c

     ! Inverse matrix operator
     function stdlib_linalg_pinv_c_operator(a) result(pinva)
         !> Input matrix a[m,n]
         complex(sp),intent(in) :: a(:,:)
         !> Result matrix
         complex(sp) :: pinva(size(a,2,kind=ilp),size(a,1,kind=ilp))

         call stdlib_linalg_pseudoinvert_c(a,pinva)

     end function stdlib_linalg_pinv_c_operator

     ! Compute the in-place pseudo-inverse of matrix a
     subroutine stdlib_linalg_pseudoinvert_z(a,pinva,rtol,err)
         !> Input matrix a[m,n]
         complex(dp),intent(inout) :: a(:,:)
         !> Output pseudo-inverse matrix
         complex(dp),intent(inout) :: pinva(:,:)
         !> [optional] ....
         real(dp),optional,intent(in) :: rtol
         !> [optional] state return flag. On error if not requested, the code will stop
         type(linalg_state),optional,intent(out) :: err

         ! Local variables
         real(dp) :: tolerance,cutoff
         real(dp),allocatable :: s(:)
         complex(dp),allocatable :: u(:,:),vt(:,:)
         type(linalg_state) :: err0
         integer(ilp) :: m,n,k,i,j
         
         ! Problem size
         m = size(a,1,kind=ilp)
         n = size(a,2,kind=ilp)
         k = min(m,n)
         if (m < 1 .or. n < 1) then
            err0 = linalg_state(this,LINALG_VALUE_ERROR,'invalid matrix size: a=', [m,n])
            call linalg_error_handling(err0,err)
            return
         end if
         
         if (any(shape(pinva,kind=ilp) /= [n,m])) then
            err0 = linalg_state(this,LINALG_VALUE_ERROR,'invalid pinv size:',shape(pinva),'should be', [n,m])
            call linalg_error_handling(err0,err)
            return
         end if
         
         ! Singular value threshold
         tolerance = max(m,n)*epsilon(0.0_dp)
         ! User value: fallback to default if <=0
         if (present(rtol)) then
            if (rtol > 0.0_dp) tolerance = rtol
         end if
         
         allocate (s(k),u(m,k),vt(k,n))
         call svd(a,s,u,vt,overwrite_a,full_matrices,err0)
         if (err0%error()) then
            err0 = linalg_state(this,LINALG_VALUE_ERROR,'svd failure -',err0%message)
            call linalg_error_handling(err0,err)
            return
         end if
         
         !> Discard singular values
         cutoff = tolerance*maxval(s)
         s = merge(1/s,0.0_dp,s > cutoff)

         ! Get pseudo-inverse: A_pinv = VT^T * diag(1/s) * U^T
         
         ! First, compute diag(1/s)*U^T in-place without transposing U
         forall (i=1:m,j=1:k) u(i,j) = s(j)*u(i,j)
            
         ! Then commutate matmul: A_pinv = VT^T * U^T = (U * VT)^T.
         ! This avoids one matrix transpose
         pinva = transpose(matmul(u,vt))

     end subroutine stdlib_linalg_pseudoinvert_z

     ! Function interface
     function stdlib_linalg_pseudoinverse_z(a,rtol,err) result(pinva)
         !> Input matrix a[m,n]
         complex(dp),intent(in) :: a(:,:)
         !> [optional] ....
         real(dp),optional,intent(in) :: rtol
         !> [optional] state return flag. On error if not requested, the code will stop
         type(linalg_state),optional,intent(out) :: err
         !> Matrix pseudo-inverse
         complex(dp) :: pinva(size(a,2,kind=ilp),size(a,1,kind=ilp))

         call stdlib_linalg_pseudoinvert_z(inva,rtol,err)

     end function stdlib_linalg_pseudoinverse_z

     ! Inverse matrix operator
     function stdlib_linalg_pinv_z_operator(a) result(pinva)
         !> Input matrix a[m,n]
         complex(dp),intent(in) :: a(:,:)
         !> Result matrix
         complex(dp) :: pinva(size(a,2,kind=ilp),size(a,1,kind=ilp))

         call stdlib_linalg_pseudoinvert_z(a,pinva)

     end function stdlib_linalg_pinv_z_operator

     ! Compute the in-place pseudo-inverse of matrix a
     subroutine stdlib_linalg_pseudoinvert_w(a,pinva,rtol,err)
         !> Input matrix a[m,n]
         complex(qp),intent(inout) :: a(:,:)
         !> Output pseudo-inverse matrix
         complex(qp),intent(inout) :: pinva(:,:)
         !> [optional] ....
         real(qp),optional,intent(in) :: rtol
         !> [optional] state return flag. On error if not requested, the code will stop
         type(linalg_state),optional,intent(out) :: err

         ! Local variables
         real(qp) :: tolerance,cutoff
         real(qp),allocatable :: s(:)
         complex(qp),allocatable :: u(:,:),vt(:,:)
         type(linalg_state) :: err0
         integer(ilp) :: m,n,k,i,j
         
         ! Problem size
         m = size(a,1,kind=ilp)
         n = size(a,2,kind=ilp)
         k = min(m,n)
         if (m < 1 .or. n < 1) then
            err0 = linalg_state(this,LINALG_VALUE_ERROR,'invalid matrix size: a=', [m,n])
            call linalg_error_handling(err0,err)
            return
         end if
         
         if (any(shape(pinva,kind=ilp) /= [n,m])) then
            err0 = linalg_state(this,LINALG_VALUE_ERROR,'invalid pinv size:',shape(pinva),'should be', [n,m])
            call linalg_error_handling(err0,err)
            return
         end if
         
         ! Singular value threshold
         tolerance = max(m,n)*epsilon(0.0_qp)
         ! User value: fallback to default if <=0
         if (present(rtol)) then
            if (rtol > 0.0_qp) tolerance = rtol
         end if
         
         allocate (s(k),u(m,k),vt(k,n))
         call svd(a,s,u,vt,overwrite_a,full_matrices,err0)
         if (err0%error()) then
            err0 = linalg_state(this,LINALG_VALUE_ERROR,'svd failure -',err0%message)
            call linalg_error_handling(err0,err)
            return
         end if
         
         !> Discard singular values
         cutoff = tolerance*maxval(s)
         s = merge(1/s,0.0_qp,s > cutoff)

         ! Get pseudo-inverse: A_pinv = VT^T * diag(1/s) * U^T
         
         ! First, compute diag(1/s)*U^T in-place without transposing U
         forall (i=1:m,j=1:k) u(i,j) = s(j)*u(i,j)
            
         ! Then commutate matmul: A_pinv = VT^T * U^T = (U * VT)^T.
         ! This avoids one matrix transpose
         pinva = transpose(matmul(u,vt))

     end subroutine stdlib_linalg_pseudoinvert_w

     ! Function interface
     function stdlib_linalg_pseudoinverse_w(a,rtol,err) result(pinva)
         !> Input matrix a[m,n]
         complex(qp),intent(in) :: a(:,:)
         !> [optional] ....
         real(qp),optional,intent(in) :: rtol
         !> [optional] state return flag. On error if not requested, the code will stop
         type(linalg_state),optional,intent(out) :: err
         !> Matrix pseudo-inverse
         complex(qp) :: pinva(size(a,2,kind=ilp),size(a,1,kind=ilp))

         call stdlib_linalg_pseudoinvert_w(inva,rtol,err)

     end function stdlib_linalg_pseudoinverse_w

     ! Inverse matrix operator
     function stdlib_linalg_pinv_w_operator(a) result(pinva)
         !> Input matrix a[m,n]
         complex(qp),intent(in) :: a(:,:)
         !> Result matrix
         complex(qp) :: pinva(size(a,2,kind=ilp),size(a,1,kind=ilp))

         call stdlib_linalg_pseudoinvert_w(a,pinva)

     end function stdlib_linalg_pinv_w_operator

end module stdlib_linalg_pseudoinverse
