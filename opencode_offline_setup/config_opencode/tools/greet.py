import sys

def greet():
    if len(sys.argv) > 1:
        name = sys.argv[1]
        print(f"Hello, {name}!")
    else:
        print("Hello, World!")

if __name__ == "__main__":
    greet()
