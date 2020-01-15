def Dressmeup(func):
    def Wrapper(*args,**kwargs):
        func.lips = 'smooth'
        func.skin= 'Brown'
        return func
    return Wrapper

@Dressmeup
def Me():
    pass

if __name__=='__main__':
    iam=Me()
    print(iam.lips,iam.skin)
