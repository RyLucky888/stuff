def Dressmeup(func):
    def Wrapper(*args,**kwargs):
        func.lips = args[0]
        func.skin=args[1]
        return func
    return Wrapper

@Dressmeup
def Me(texture,color):
    pass

if __name__=='__main__':
    iam=Me('smooth','beautiful')
    print(iam.lips,iam.skin)
