************************************************************************
*  Subroutine: Setup_Derivatives                                       
*                                                                      
*  Performs initialization for the derivative routines. This routine
*  must be called before any derivative is calculated. It is
*  responsible for defining the left hand matrix of the compact
*  difference scheme and performing LDU decomposition on them.         
************************************************************************
      Subroutine Setup_Derivatives

      Include 'header'

*  Locals
      Integer I, J, K, N

*  x,y and z derivatives are optimized periodic sixth order Pade schemes
*
*  First derivative:
*
*  beta * f'(I-2) + alpha * f'(I-1) + f'(I) + 
*
*  beta * f'(I+2) + alpha * f'(I+1) 
*
*         [ f(I+3) - f(I-3) ]       [ f(I+2) - f(I-2) ]
*    = c --------------------- + b ---------------------
*                 6 h                       4 h
*
*                                   [ f(I+1) - f(I-1) ]
*                              + a ---------------------
*                                           2 h
*
*  where
*
*    a   =   1.367577724399269  E+00
*    b   =   8.234281701082790  E-01
*    c   =   1.8520783486686603 E-02
*  alpha =   5.381301488732363  E-01
*   beta =   6.6633190123881123 E-02

      Do N = 1, LotX  ! (My * Mz)
        Do I = 1,Mx
          ldu_x_A1(N,I) = beta1_pade6
          ldu_x_B1(N,I) = alpha1_pade6
          ldu_x_C1(N,I) = 1.0D0
          ldu_x_D1(N,I) = alpha1_pade6
          ldu_x_E1(N,I) = beta1_pade6
        End Do
      End Do

      Do N = 1, LotY  ! (Mz * Mx)
        Do J = 1,My
          ldu_y_A1(N,J) = beta1_pade6
          ldu_y_B1(N,J) = alpha1_pade6
          ldu_y_C1(N,J) = 1.0D0
          ldu_y_D1(N,J) = alpha1_pade6
          ldu_y_E1(N,J) = beta1_pade6
        End Do
      End Do

      Do N = 1, LotZ  ! (Mx * My)
        Do K = 1,Mz
          ldu_z_A1(N,K) = beta1_pade6
          ldu_z_B1(N,K) = alpha1_pade6
          ldu_z_C1(N,K) = 1.0D0
          ldu_z_D1(N,K) = alpha1_pade6
          ldu_z_E1(N,K) = beta1_pade6
        End Do
      End Do

*  Second derivative:
*
*  beta * f''(I-2) + alpha * f''(I-1) + f''(I) + 
*
*  beta * f''(I+2) + alpha * f''(I+1) 
*
*         [ f(I+3) - 2 f(I) + f(I-3) ]
*    = c ------------------------------
*                    9 h^2
*
*         [ f(I+2) - 2 f(I) + f(I-2) ]
*    + b ------------------------------
*                    4 h^2
*
*         [ f(I+1) - 2 f(I) + f(I-1) ]
*    + a ------------------------------
*                     h^2
*
*  where
*
*    a   =   3.855624784762861  E-01
*    b   =   1.486194872274852  E+00
*    c   =   9.3303618061543067 E-02
*  alpha =   4.442052422604100  E-01
*   beta =   3.8325242145930416 E-02

      Do N = 1,LotX
        Do I = 1,Mx
          ldu_x_A2(N,I) = beta2_pade6
          ldu_x_B2(N,I) = alpha2_pade6
          ldu_x_C2(N,I) = 1.0D0
          ldu_x_D2(N,I) = alpha2_pade6
          ldu_x_E2(N,I) = beta2_pade6
        End Do
      End Do

      Do N = 1,LotY
        Do J = 1,My
          ldu_y_A2(N,J) = beta2_pade6
          ldu_y_B2(N,J) = alpha2_pade6
          ldu_y_C2(N,J) = 1.0D0
          ldu_y_D2(N,J) = alpha2_pade6
          ldu_y_E2(N,J) = beta2_pade6
        End Do
      End Do

      Do N = 1,LotZ
        Do K = 1,Mz
          ldu_z_A2(N,K) = beta2_pade6
          ldu_z_B2(N,K) = alpha2_pade6
          ldu_z_C2(N,K) = 1.0D0
          ldu_z_D2(N,K) = alpha2_pade6
          ldu_z_E2(N,K) = beta2_pade6
        End Do
      End Do

      End


************************************************************************
*  Subroutines: DFDX, DFDY, DFxzDZ, DFyzDZ (1st derivatives)
*               D2FDX2, D2FDY2, D2FxzDZ2, D2FyzDZ2 (2nd derivatives)
*
* These routines calculate the derivative of the scalar field F using
* compact difference schemes and assuming periodicity in all directions.
* They define the right hand vectors of the linear systems of
* equations resulting from the compact difference schemes. They then
* call a routine to solve the systems of equations.
*
* In: F (scalar field to be differentiated)
*     cadd (multiplicative factor)
*
* Out: dF, d2F: derivative of F
*
* Note: The x- and y-routines have the same structure but the
*       z-routines have not!
*
* z-Routines: The xz-versions are used where the processors hold entire
*             xz-planes whereas the yz-versions are used where the
*             processors store entire yz-planes.
*                                                                      
*  First derivatives                          
*  iadd = 0 : dF =       cadd * s1* df/ds
*  iadd = 1 : dF =  dF + cadd * s1* df/ds
*  Coupled derivatives:                                                
*  dF  = cadd * s1 * df/ds                                             
*  d2F = cadd * s2 * d2f/ds2                                           
*                                                                      
*  where                                                               
*    s1 = 1 / (dx_i/ds)                                                
*    s2 = s1 * s1                                                      
************************************************************************

************************************************************************
      Subroutine DFDX(F, dF, iadd, cadd)

      Include 'header'
      Include 'mpif.h'

      Integer iadd
      Real*8  cadd
      Real*8  F(My,Mz,Mx), dF(My,Mz,Mx)
      Real*8  FP(My,Mz,3), FN(My,Mz,3)   
      Real*8  W(LotX, Mx), W2(My,Mz,Mx)
      Real*8  temp(My,Mz,3,2)
      Integer status_arr(MPI_STATUS_SIZE,4), ierr, req(4)

*  Locals
      Integer I, J, K, N
      Real*8  fac

      fac = cadd * sx(1) * (Nx - 1)        ! NB: sx(1)*(Nx-1) = 1 / dx

* Putting first 3 and last 3 data planes into temp arrays for sending
      temp(:,:,:,1) = F(:,:,1:3)
      temp(:,:,:,2) = F(:,:,Mx-2:Mx)

* Transferring data from neighbouring processors
      Call MPI_IRECV(FP(1,1,1),    My*Mz*3, MPI_REAL8,source_right_x,
     .               source_right_x,                                 ! Recv last 3 planes
     .               MPI_XYZ_COMM, req(1), ierr)

      Call MPI_IRECV(FN(1,1,1),    My*Mz*3, MPI_REAL8,source_left_x,
     .               source_left_x,                                  ! Recv first 3 planes
     .               MPI_XYZ_COMM, req(2), ierr)

      Call MPI_ISEND(temp(1,1,1,2), My*Mz*3, MPI_REAL8,dest_right_x,
     .               rank,                                           ! Send last 3 planes
     .               MPI_XYZ_COMM, req(3), ierr)

      Call MPI_ISEND(temp(1,1,1,1), My*Mz*3, MPI_REAL8,dest_left_x,
     .               rank,                                           ! Send first 3 planes
     .               MPI_XYZ_COMM, req(4), ierr)

* Compute interior in the meantime
      Do J = 1, My
       Do K = 1, Mz
         Do I = 4, Mx-3
          N =  (J-1) * Mz + K
          W(N,I) = fac * (    c1_pade6 * ( F(J,K,I+3) - F(J,K,I-3) )
     .                      + b1_pade6 * ( F(J,K,I+2) - F(J,K,I-2) )
     .                      + a1_pade6 * ( F(J,K,I+1) - F(J,K,I-1) ) )
         End Do
       End Do
      End Do

*  Wait to recieve planes
      Call MPI_WAITALL(4, req, status_arr, ierr)  
 
      Do J = 1, My
        Do K = 1, Mz
        
          N =  (J-1) * Mz + K       
 
          W(N,1) = fac * (    c1_pade6 * ( F(J,K,4) - FP(J,K,1) )
     .                      + b1_pade6 * ( F(J,K,3) - FP(J,K,2) )
     .                      + a1_pade6 * ( F(J,K,2) - FP(J,K,3) ) )
          W(N,2) = fac * (    c1_pade6 * ( F(J,K,5) - FP(J,K,2) )
     .                      + b1_pade6 * ( F(J,K,4) - FP(J,K,3) )
     .                      + a1_pade6 * ( F(J,K,3) -  F(J,K,1) ) )
          W(N,3) = fac * (    c1_pade6 * ( F(J,K,6) - FP(J,K,3) )
     .                      + b1_pade6 * ( F(J,K,5) -  F(J,K,1) )
     .                      + a1_pade6 * ( F(J,K,4) -  F(J,K,2) ) )

        End Do
      End Do

      Do J = 1, My
        Do K = 1, Mz

          N =  (J-1) * Mz + K

          W(N,Mx-2) = fac * (
     .                        c1_pade6 * ( FN(J,K,1)   - F(J,K,Mx-5) )
     .                      + b1_pade6 * ( F(J,K,Mx)   - F(J,K,Mx-4) )
     .                      + a1_pade6 * ( F(J,K,Mx-1) - F(J,K,Mx-3) ) )
          W(N,Mx-1) = fac * (
     .                        c1_pade6 * ( FN(J,K,2)   - F(J,K,Mx-4) )
     .                      + b1_pade6 * ( FN(J,K,1)   - F(J,K,Mx-3) )
     .                      + a1_pade6 * ( F(J,K,Mx)   - F(J,K,Mx-2) ) )
          W(N,  Mx) = fac * (
     .                        c1_pade6 * ( FN(J,K,3)   - F(J,K,Mx-3) )
     .                      + b1_pade6 * ( FN(J,K,2)   - F(J,K,Mx-2) )
     .                      + a1_pade6 * ( FN(J,K,1)   - F(J,K,Mx-1) ) )
        End Do
      End Do

*  Solve the matrix system to obtain the derivative dF
      Call pentadiagonal(ldu_x_A1, ldu_x_B1, ldu_x_C1,
     .                   ldu_x_D1, ldu_x_E1, W, 
     .                   Mx, LotX, 1, MPI_X_COMM)

* Converting 2-D array to 3-D for copying
      Do N = 0,LotX-1
       Do I = 1,Mx
         J = N / Mz + 1
         K = MOD(N,Mz) + 1
         W2(J,K,I) = W(N+1,I)
       End Do
      End Do

      if(iadd .EQ. 0)Then
          dF = W2 
      Else if(iadd .EQ. 1)Then 
          dF = dF + W2
      End if

      End


************************************************************************
      Subroutine D2FDX2(F, dF, d2F, iadd)

      Include 'header'
      Include 'mpif.h'

      Integer iadd
      Real*8  cadd
      Real*8  F(My,Mz,Mx), dF(My,Mz,Mx), d2F(My,Mz,Mx)
      Real*8  FP(My,Mz,3), FN(My,Mz,3)
      Real*8  W(LotX, Mx), W2(My,Mz,Mx)
      Real*8  temp(My,Mz,3,2)
      Integer status_arr(MPI_STATUS_SIZE,4), ierr, req(4)

*  Locals
      Integer I, J, K, N
      Real*8 fac

      fac = ((Nx - 1) * (Nx - 1)) * sx(2)

* Putting first 3 and last 3 data planes into temp arrays for sending
      temp(:,:,:,1) = F(:,:,1:3)
      temp(:,:,:,2) = F(:,:,Mx-2:Mx)

* Transferring data from neighbouring processors
      Call MPI_IRECV(FP(1,1,1),    My*Mz*3, MPI_REAL8,source_right_x,
     .                  source_right_x,                                 ! Recv last 3 planes
     .                  MPI_XYZ_COMM, req(1), ierr)

      Call MPI_IRECV(FN(1,1,1),    My*Mz*3, MPI_REAL8,source_left_x,
     .                  source_left_x,                                  ! Recv first 3 planes
     .                  MPI_XYZ_COMM, req(2), ierr)

      Call MPI_ISEND(temp(1,1,1,2), My*Mz*3, MPI_REAL8,dest_right_x,
     .               rank,                                           ! Send last 3 planes
     .               MPI_XYZ_COMM, req(3), ierr)

      Call MPI_ISEND(temp(1,1,1,1), My*Mz*3, MPI_REAL8,dest_left_x,
     .               rank,                                           ! Send first 3 planes
     .               MPI_XYZ_COMM, req(4), ierr)

* Compute interior in the meantime
      Do J = 1, My
        Do K = 1, Mz
          Do I = 4, Mx-3
            N =  (J-1) * Mz + K
            W(N,I) = fac *( c2_pade6 * ( F(J,K,I+3) + F(J,K,I-3) ) +
     .                          b2_pade6 * ( F(J,K,I+2) + F(J,K,I-2) ) +
     .                          a2_pade6 * ( F(J,K,I+1) + F(J,K,I-1) ) -
     .                          d2_pade6 *   F(J,K,I  ) )
          End Do
        End Do
      End Do

*  Wait to recieve planes
      Call MPI_WAITALL(4, req, status_arr, ierr)

      Do J = 1, My
        Do K = 1, Mz

          N =  (J-1) * Mz + K

          W(N,1) = fac * ( c2_pade6 * ( F(J,K,4) + FP(J,K,1) ) +
     .                         b2_pade6 * ( F(J,K,3) + FP(J,K,2) ) +
     .                         a2_pade6 * ( F(J,K,2) + FP(J,K,3) ) -
     .                         d2_pade6 *   F(J,K,1) )
          W(N,2) = fac * ( c2_pade6 * ( F(J,K,5) + FP(J,K,2) ) +
     .                         b2_pade6 * ( F(J,K,4) + FP(J,K,3) ) +
     .                         a2_pade6 * ( F(J,K,3) + F(J,K,1)  ) -
     .                         d2_pade6 *   F(J,K,2) )
          W(N,3) = fac * ( c2_pade6 * ( F(J,K,6) + FP(J,K,3) ) +
     .                         b2_pade6 * ( F(J,K,5) + F(J,K,1) ) +
     .                         a2_pade6 * ( F(J,K,4) + F(J,K,2) ) -
     .                         d2_pade6 *   F(J,K,3) )

        End Do
      End Do

      Do J = 1, My
        Do K = 1, Mz
 
          N =  (J-1) * Mz + K

          W(N,Mx-2) = fac * ( 
     .                       c2_pade6 * ( FN(J,K,1)   + F(J,K,Mx-5) ) +
     .                       b2_pade6 * ( F(J,K,Mx)   + F(J,K,Mx-4) ) +
     .                       a2_pade6 * ( F(J,K,Mx-1) + F(J,K,Mx-3) ) -
     .                       d2_pade6 *   F(J,K,Mx-2) )
          W(N,Mx-1) = fac * ( 
     .                       c2_pade6 * ( FN(J,K,2) + F(J,K,Mx-4) ) +
     .                       b2_pade6 * ( FN(J,K,1) + F(J,K,Mx-3) ) +
     .                       a2_pade6 * ( F(J,K,Mx) + F(J,K,Mx-2) ) -
     .                       d2_pade6 *   F(J,K,Mx-1) )
          W(N,  Mx) = fac * ( 
     .                       c2_pade6 * ( FN(J,K,3) + F(J,K,Mx-3) ) +
     .                       b2_pade6 * ( FN(J,K,2) + F(J,K,Mx-2) ) +
     .                       a2_pade6 * ( FN(J,K,1) + F(J,K,Mx-1) ) - 
     .                       d2_pade6 *   F(J,K,Mx) )
        End Do
      End Do
   
      if(iadd .EQ. 1) Call DFDX(F,dF,0,1.0D0)
 
*  Solve the matrix system to obtain the derivative dF
      Call pentadiagonal(ldu_x_A2, ldu_x_B2, ldu_x_C2,
     .                   ldu_x_D2, ldu_x_E2, W,
     .                   Mx, LotX, 1, MPI_X_COMM)

* Converting 2-D array to 3-D for copying
      Do N = 0,LotX-1
       Do I = 1,Mx
         J = N / Mz + 1
         K = MOD(N,Mz) + 1
         d2F(J,K,I) = W(N+1,I)
       End Do
      End Do

      End

************************************************************************
      Subroutine DFDY(F, dF, iadd, cadd)

      Include 'header'
      Include 'mpif.h'

      Integer iadd
      Real*8  cadd
      Real*8  F(My,Mz,Mx), dF(My,Mz,Mx)
      Real*8  FP(3,Mz,Mx), FN(3,Mz,Mx)
      Real*8  W(LotY, My), W2(My,Mz,Mx)
      Real*8  temp(3,Mz,Mx,2)
      Integer status_arr(MPI_STATUS_SIZE,4), ierr, req(4)

*  Locals
      Integer I, J, K, N
      Real*8  fac

      fac = cadd * sy(1) * (Ny - 1)       ! NB: sy(1)*(Ny-1) = 1 / dy

      temp(:,:,:,1) = F(1:3,:,:)
      temp(:,:,:,2) = F(My-2:My,:,:)

* Transferring data from neighbouring processors
      Call MPI_IRECV(FP(1,1,1),    Mz*Mx*3, MPI_REAL8,source_right_y,
     .               source_right_y,                                 ! Recv last 3 planes
     .               MPI_XYZ_COMM, req(1), ierr)

      Call MPI_IRECV(FN(1,1,1),    Mz*Mx*3, MPI_REAL8,source_left_y ,
     .               source_left_y,                                  ! Recv first 3 planes
     .               MPI_XYZ_COMM, req(2), ierr)

      Call MPI_ISEND(temp(1,1,1,2), Mz*Mx*3, MPI_REAL8,dest_right_y,
     .               rank,                                           ! Send last 3 planes
     .               MPI_XYZ_COMM, req(3), ierr)

      Call MPI_ISEND(temp(1,1,1,1), Mz*Mx*3, MPI_REAL8,dest_left_y,
     .               rank,                                           ! Send first 3 planes
     .               MPI_XYZ_COMM, req(4), ierr)

* Compute interior in the meantime
      Do I = 1, Mx
        Do K = 1, Mz
          N =  (I-1) * Mz + K
          Do J = 4, My-3
            W(N,J) = fac * (    c1_pade6 * ( F(J+3,K,I) - F(J-3,K,I) )
     .                        + b1_pade6 * ( F(J+2,K,I) - F(J-2,K,I) )
     .                        + a1_pade6 * ( F(J+1,K,I) - F(J-1,K,I) ) )
          End Do
        End Do
      End Do

*  Wait to recieve planes
      Call MPI_WAITALL(4, req, status_arr, ierr)

      Do I = 1, Mx
        Do K = 1, Mz

          N =  (I-1) * Mz + K

          W(N,1) = fac * (    c1_pade6 * ( F(4,K,I) - FP(1,K,I) ) 
     .                      + b1_pade6 * ( F(3,K,I) - FP(2,K,I) )
     .                      + a1_pade6 * ( F(2,K,I) - FP(3,K,I) ) )
          W(N,2) = fac * (    c1_pade6 * ( F(5,K,I) - FP(2,K,I) ) 
     .                      + b1_pade6 * ( F(4,K,I) - FP(3,K,I) )
     .                      + a1_pade6 * ( F(3,K,I) -  F(1,K,I) ) )
          W(N,3) = fac * (    c1_pade6 * ( F(6,K,I) - FP(3,K,I) ) 
     .                      + b1_pade6 * ( F(5,K,I) -  F(1,K,I) )
     .                      + a1_pade6 * ( F(4,K,I) -  F(2,K,I) ) )
        End Do
      End Do
    
      Do I = 1, Mx
        Do K = 1, Mz

          N =  (I-1) * Mz + K

          W(N,My-2) = fac * ( 
     .                        c1_pade6 * ( FN(1,K,I)   - F(My-5,K,I) )
     .                      + b1_pade6 * ( F(My,K,I)   - F(My-4,K,I) )
     .                      + a1_pade6 * ( F(My-1,K,I) - F(My-3,K,I) ) )
          W(N,My-1) = fac * ( 
     .                        c1_pade6 * ( FN(2,K,I) - F(My-4,K,I) ) 
     .                      + b1_pade6 * ( FN(1,K,I) - F(My-3,K,I) )
     .                      + a1_pade6 * ( F(My,K,I) - F(My-2,K,I) ) )
          W(N,  My) = fac * ( 
     .                        c1_pade6 * ( FN(3,K,I) - F(My-3,K,I) ) 
     .                      + b1_pade6 * ( FN(2,K,I) - F(My-2,K,I) )
     .                      + a1_pade6 * ( FN(1,K,I) - F(My-1,K,I) ) )
        End Do
      End Do

*  Solve the matrix system to obtain the derivative dF
      Call pentadiagonal(ldu_y_A1, ldu_y_B1, ldu_y_C1,
     .                   ldu_y_D1, ldu_y_E1, W,
     .                   My, LotY, 1, MPI_Y_COMM)

* Converting 2-D array to 3-D for copying
      Do N = 0,LotY-1
       Do J = 1,My
         I = N / Mz + 1
         K = MOD(N,Mz) + 1
         W2(J,K,I) = W(N+1,J)
       End Do
      End Do

* Copying solution array to output matrix
      if(iadd .EQ. 0)Then
          dF = W2
      Else if(iadd .EQ. 1)Then
          dF = dF + W2
      End if

      End

************************************************************************
      Subroutine D2FDY2(F, dF, d2F, iadd)

      Include 'header'
      Include 'mpif.h'

      Integer iadd
      Real*8 cadd
      Real*8  F(My,Mz,Mx), dF(My,Mz,Mx), d2F(My,Mz,Mx)
      Real*8  FP(3,Mz,Mx), FN(3,Mz,Mx)
      Real*8  W(LotY, My), W2(My,Mz,Mx)
      Real*8  temp(3,Mz,Mx,2)
      Integer status_arr(MPI_STATUS_SIZE,4), ierr, req(4)

*  Locals
      Integer I, J, K, N
      Real*8  fac

      fac  = ((Ny - 1) * (Ny - 1)) * sy(2)

      temp(:,:,:,1) = F(1:3,:,:)
      temp(:,:,:,2) = F(My-2:My,:,:)

* Transferring data from neighbouring processors
      Call MPI_IRECV(FP(1,1,1),    Mz*Mx*3, MPI_REAL8,source_right_y,
     .               source_right_y,                                 ! Recv last 3 planes
     .               MPI_XYZ_COMM, req(1), ierr)

      Call MPI_IRECV(FN(1,1,1),    Mz*Mx*3, MPI_REAL8,source_left_y ,
     .               source_left_y,                                  ! Recv first 3 planes
     .               MPI_XYZ_COMM, req(2), ierr)

      Call MPI_ISEND(temp(1,1,1,2), Mz*Mx*3, MPI_REAL8,dest_right_y,
     .               rank,                                           ! Send last 3 planes
     .               MPI_XYZ_COMM, req(3), ierr)
      Call MPI_ISEND(temp(1,1,1,1), Mz*Mx*3, MPI_REAL8,dest_left_y,
     .               rank,                                           ! Send first 3 planes
     .               MPI_XYZ_COMM, req(4), ierr)
 
* Compute interior in the meantime
      Do I = 1, Mx
        Do K = 1, Mz
          N =  (I-1) * Mz + K
          Do J = 4, My-3
            W(N,J) = fac *( c2_pade6 * ( F(J+3,K,I) + F(J-3,K,I) ) +
     .                      b2_pade6 * ( F(J+2,K,I) + F(J-2,K,I) ) +
     .                      a2_pade6 * ( F(J+1,K,I) + F(J-1,K,I) ) -
     .                      d2_pade6 *   F(J,K,I) )
          End Do
        End Do
      End Do

*  Wait to recieve planes
      Call MPI_WAITALL(4, req, status_arr, ierr)

      Do I = 1, Mx
        Do K = 1, Mz

          N =  (I-1) * Mz + K

          W(N,1) = fac * ( c2_pade6 * ( F(4,K,I) + FP(1,K,I) ) +
     .                     b2_pade6 * ( F(3,K,I) + FP(2,K,I) ) +
     .                     a2_pade6 * ( F(2,K,I) + FP(3,K,I) ) -
     .                     d2_pade6 *   F(1,K,I) )
          W(N,2) = fac * ( c2_pade6 * ( F(5,K,I) + FP(2,K,I) ) +
     .                     b2_pade6 * ( F(4,K,I) + FP(3,K,I) ) +
     .                     a2_pade6 * ( F(3,K,I) + F(1,K,I)  ) -
     .                     d2_pade6 *   F(2,K,I) )
          W(N,3) = fac * ( c2_pade6 * ( F(6,K,I) + FP(3,K,I) ) +
     .                     b2_pade6 * ( F(5,K,I) + F(1,K,I)  ) +
     .                     a2_pade6 * ( F(4,K,I) + F(2,K,I)  ) - 
     .                     d2_pade6 *   F(3,K,I) )
        End Do
      End Do

      Do I = 1, Mx
        Do K = 1, Mz

          N =  (I-1) * Mz + K

          W(N,My-2) = fac * (
     .                       c2_pade6 * ( FN(1,K,I) + F(My-5,K,I)   ) +
     .                       b2_pade6 * ( F(My,K,I) + F(My-4,K,I)   ) +
     .                       a2_pade6 * ( F(My-1,K,I) + F(My-3,K,I) ) - 
     .                       d2_pade6 *   F(My-2,K,I) )
          W(N,My-1) = fac * (
     .                       c2_pade6 * ( FN(2,K,I) + F(My-4,K,I) ) +
     .                       b2_pade6 * ( FN(1,K,I) + F(My-3,K,I) ) +
     .                       a2_pade6 * ( F(My,K,I) + F(My-2,K,I) ) -
     .                       d2_pade6 *   F(My-1,K,I) )
          W(N,  My) = fac * (
     .                       c2_pade6 * ( FN(3,K,I) + F(My-3,K,I) ) +
     .                       b2_pade6 * ( FN(2,K,I) + F(My-2,K,I) ) +
     .                       a2_pade6 * ( FN(1,K,I) + F(My-1,K,I) ) - 
     .                       d2_pade6 *   F(My,K,I) )
        End Do
      End Do
   
      if(iadd .EQ. 1) Call DFDY(F,dF,0,1.0D0)

*  Solve the matrix system to obtain the derivative dF
      Call pentadiagonal(ldu_y_A2, ldu_y_B2, ldu_y_C2,
     .                   ldu_y_D2, ldu_y_E2, W,
     .                   My, LotY, 1, MPI_Y_COMM)

* Converting 2-D array to 3-D for copying
      Do N = 0,LotY-1
       Do J = 1,My
         I = N / Mz + 1
         K = MOD(N,Mz) + 1
         d2F(J,K,I) = W(N+1,J)
       End Do
      End Do

      End

************************************************************************
      Subroutine DFDZ(F, dF, iadd, cadd)

      Include 'header'
      Include 'mpif.h'
       
      Integer iadd
      Real*8  cadd
      Real*8  F(My,Mz,Mx), dF(My,Mz,Mx)
      Real*8  FP(My,3,Mx), FN(My,3,Mx)
      Real*8  W(LotZ, Mz), W2(My,Mz,Mx)
      Real*8  temp(My,3,Mx,2)
      Integer status_arr(MPI_STATUS_SIZE,4), ierr, req(4)

*  Locals
      Integer I, J, K, N
      Real*8  fac

      fac = cadd * sz(1) * (Nz - 1)        ! NB: sz(1)*(Nz-1) = 1 / dz

* Putting first 3 and last 3 data planes into temp arrays for sending
      temp(:,:,:,1) = F(:,1:3,:)
      temp(:,:,:,2) = F(:,Mz-2:Mz,:)

* Transferring data from neighbouring processors
      Call MPI_IRECV(FP(1,1,1),    Mx*My*3, MPI_REAL8,source_right_z,
     .               source_right_z,                                 ! Recv last 3 planes
     .               MPI_XYZ_COMM, req(1), ierr)

      Call MPI_IRECV(FN(1,1,1),    Mx*My*3, MPI_REAL8,source_left_z,
     .               source_left_z,                                  ! Recv first 3 planes
     .               MPI_XYZ_COMM, req(2), ierr)

      Call MPI_ISEND(temp(1,1,1,2), Mx*My*3, MPI_REAL8,dest_right_z,
     .               rank,                                           ! Send last 3 planes
     .               MPI_XYZ_COMM, req(3), ierr)

      Call MPI_ISEND(temp(1,1,1,1), Mx*My*3, MPI_REAL8,dest_left_z,
     .               rank,                                           ! Send first 3 planes
     .               MPI_XYZ_COMM, req(4), ierr)

* Compute interior in the meantime
      Do I = 1, Mx
        Do J = 1, My
          N =  (I-1) * My + J
          Do K = 4, Mz-3
            W(N,K) = fac * ( c1_pade6 * ( F(J,K+3,I) - F(J,K-3,I) )
     .                    +  b1_pade6 * ( F(J,K+2,I) - F(J,K-2,I) )
     .                    +  a1_pade6 * ( F(J,K+1,I) - F(J,K-1,I) ) )
          End Do
        End Do
      End Do

*  Wait to recieve planes
      Call MPI_WAITALL(4, req, status_arr, ierr)

      Do I = 1, Mx
        Do J = 1, My

          N =  (I-1) * My + J

          W(N,1) = fac * ( c1_pade6 * ( F(J,4,I) - FP(J,1,I) ) 
     .                  +  b1_pade6 * ( F(J,3,I) - FP(J,2,I) )
     .                  +  a1_pade6 * ( F(J,2,I) - FP(J,3,I) ) )
          W(N,2) = fac * ( c1_pade6 * ( F(J,5,I) - FP(J,2,I) ) 
     .                  +  b1_pade6 * ( F(J,4,I) - FP(J,3,I) )
     .                  +  a1_pade6 * ( F(J,3,I) -  F(J,1,I) ) )
          W(N,3) = fac * ( c1_pade6 * ( F(J,6,I) - FP(J,3,I) ) 
     .                  +  b1_pade6 * ( F(J,5,I) -  F(J,1,I) )
     .                  +  a1_pade6 * ( F(J,4,I) -  F(J,2,I) ) )
        End Do
      End Do

      Do I = 1, Mx
        Do J = 1, My

          N =  (I-1) * My + J

          W(N,Mz-2) = fac * ( 
     .                       c1_pade6 * ( FN(J,1,I)   - F(J,Mz-5,I) ) 
     .                     + b1_pade6 * ( F(J,Mz,I)   - F(J,Mz-4,I) )
     .                     + a1_pade6 * ( F(J,Mz-1,I) - F(J,Mz-3,I) ) )
          W(N,Mz-1) = fac * ( 
     .                       c1_pade6 * ( FN(J,2,I) - F(J,Mz-4,I) ) 
     .                     + b1_pade6 * ( FN(J,1,I) - F(J,Mz-3,I) )
     .                     + a1_pade6 * ( F(J,Mz,I) - F(J,Mz-2,I) ) )
          W(N,  Mz) = fac * ( 
     .                       c1_pade6 * ( FN(J,3,I) - F(J,Mz-3,I) ) 
     .                     + b1_pade6 * ( FN(J,2,I) - F(J,Mz-2,I) )
     .                     + a1_pade6 * ( FN(J,1,I) - F(J,Mz-1,I) ) )
        End Do
      End Do

*  Solve the matrix system to obtain the derivative dF
      Call pentadiagonal(ldu_z_A1, ldu_z_B1, ldu_z_C1,
     .                   ldu_z_D1, ldu_z_E1, W,
     .                   Mz, LotZ, 1, MPI_Z_COMM)

* Converting 2-D array to 3-D for copying
      Do N = 0,LotZ-1
       Do K = 1,Mz
         I = N / My + 1
         J = MOD(N,My) + 1
         W2(J,K,I) = W(N+1,K)
       End Do
      End Do

* Copying solution array to output matrix
      if(iadd .EQ. 0)Then
          dF = W2
      Else if(iadd .EQ. 1)Then
          dF = dF + W2
      End if

      End

************************************************************************
      Subroutine D2FDZ2(F, dF, d2F, iadd)

      Include 'header'
      Include 'mpif.h'

      Integer iadd
      Real*8  cadd
      Real*8  F(My,Mz,Mx), dF(My,Mz,Mx), d2F(My,Mz,Mx)
      Real*8  FP(My,3,Mx), FN(My,3,Mx)
      Real*8  W(LotZ, Mz), W2(My,Mz,Mx)
      Real*8  temp(My,3,Mx,2)
      Integer status_arr(MPI_STATUS_SIZE,4), ierr, req(4)

*  Locals
      Integer I, J, K, N
      Real*8  fac

      fac = ((Nz - 1) * (Nz - 1)) * sz(2)

* Putting first 3 and last 3 data planes into temp arrays for sending
      temp(:,:,:,1) = F(:,1:3,:)
      temp(:,:,:,2) = F(:,Mz-2:Mz,:)

* Transferring data from neighbouring processors
      Call MPI_IRECV(FP(1,1,1),    Mx*My*3, MPI_REAL8,source_right_z,
     .                  source_right_z,                                 ! Recv last 3 planes
     .                  MPI_XYZ_COMM, req(1), ierr)

      Call MPI_IRECV(FN(1,1,1),    Mx*My*3, MPI_REAL8,source_left_z,
     .                  source_left_z,                                  ! Recv first 3 planes
     .                  MPI_XYZ_COMM, req(2), ierr)

      Call MPI_ISEND(temp(1,1,1,2), Mx*My*3, MPI_REAL8,dest_right_z,
     .                  rank,                                           ! Send last 3 planes
     .               MPI_XYZ_COMM, req(3), ierr)
 
      Call MPI_ISEND(temp(1,1,1,1), Mx*My*3, MPI_REAL8,dest_left_z,
     .                  rank,                                           ! Send first 3 planes
     .               MPI_XYZ_COMM, req(4), ierr)

* Compute interior in the meantime
      Do I = 1, Mx
        Do J = 1, My
          N =  (I-1) * My + J
          Do K = 4, Mz-3
            W(N,K) = fac * ( c2_pade6 * ( F(J,K+3,I) + F(J,K-3,I) ) +
     .                       b2_pade6 * ( F(J,K+2,I) + F(J,K-2,I) ) +
     .                       a2_pade6 * ( F(J,K+1,I) + F(J,K-1,I) ) -
     .                       d2_pade6 *   F(J,K,  I) )
          End Do
        End Do
      End Do

*  Wait to recieve last 3 planes
      Call MPI_WAITALL(4, req, status_arr, ierr)

      Do I = 1, Mx
        Do J = 1, My

          N =  (I-1) * My + J

          W(N,1) = fac * ( c2_pade6 * ( F(J,4,I) + FP(J,1,I) ) +
     .                     b2_pade6 * ( F(J,3,I) + FP(J,2,I) ) +
     .                     a2_pade6 * ( F(J,2,I) + FP(J,3,I) ) - 
     .                     d2_pade6 *   F(J,1,I) )
          W(N,2) = fac * ( c2_pade6 * ( F(J,5,I) + FP(J,2,I) ) +
     .                     b2_pade6 * ( F(J,4,I) + FP(J,3,I) ) +
     .                     a2_pade6 * ( F(J,3,I) + F(J,1,I)  ) -
     .                     d2_pade6 *   F(J,2,I) )
          W(N,3) = fac * ( c2_pade6 * ( F(J,6,I) + FP(J,3,I) ) +
     .                     b2_pade6 * ( F(J,5,I) + F(J,1,I)  ) +
     .                     a2_pade6 * ( F(J,4,I) + F(J,2,I)  ) -
     .                     d2_pade6 *   F(J,3,I) )
        End Do
      End Do

      Do I = 1, Mx
        Do J = 1, My

          N =  (I-1) * My + J

          W(N,Mz-2) = fac * (
     .                       c2_pade6 * ( FN(J,1,   I) + F(J,Mz-5,I) ) +
     .                       b2_pade6 * ( F(J,Mz,  I) + F(J,Mz-4,I) ) +
     .                       a2_pade6 * ( F(J,Mz-1,I) + F(J,Mz-3,I) ) -
     .                       d2_pade6 *   F(J,Mz-2,I) )
          W(N,Mz-1) = fac * (
     .                       c2_pade6 * ( FN(J,2,   I) + F(J,Mz-4,I) ) +
     .                       b2_pade6 * ( FN(J,1,   I) + F(J,Mz-3,I) ) +
     .                       a2_pade6 * ( F(J,Mz,  I) + F(J,Mz-2,I) ) -
     .                       d2_pade6 *   F(J,Mz-1,I) )
          W(N,  Mz) = fac * (
     .                       c2_pade6 * ( FN(J,3,   I) + F(J,Mz-3,I) ) +
     .                       b2_pade6 * ( FN(J,2,   I) + F(J,Mz-2,I) ) +
     .                       a2_pade6 * ( FN(J,1,   I) + F(J,Mz-1,I) ) -
     .                       d2_pade6 *   F(J,Mz,  I) )
        End Do
      End Do

      if(iadd .EQ. 1) Call DFDZ(F, dF, 0, 1.0D0)

*  Solve the matrix system to obtain the derivative dF
      Call pentadiagonal(ldu_z_A2, ldu_z_B2, ldu_z_C2,
     .                   ldu_z_D2, ldu_z_E2, W,
     .                   Mz, LotZ, 1, MPI_Z_COMM)

* Converting 2-D array to 3-D for copying
      Do N = 0,LotZ-1
       Do K = 1,Mz
         I = N / My + 1
         J = MOD(N,My) + 1
         d2F(J,K,I) = W(N+1,K)
       End Do
      End Do

      End
