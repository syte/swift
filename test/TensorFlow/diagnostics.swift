// RUN: %target-swift-frontend -O -emit-sil -verify %s

import TensorFlow


// Show inference of the tensor element type based on context.  This also
// exposed a SILGen bug handling cleanup generation when emitting into let
// declarations.
@_transparent
func testInferredElementResult() -> TensorHandle<Int32> {
  // expected-warning @+1 {{immutable value 'x' was never used}}
  let x : TensorHandle<Int32> = #tfop("foo")

  _ = #tfop("bar") as TensorHandle<Int32>
}

// This shows passing a non-constant value into an attribute.
// TODO: Improve this to talk about the parameter "keepingDimensions" instead
// of the internal attribute name.
public func nonConstantAttribute(x: Tensor<Float>, someBool: Bool) {
  // expected-error @+1 {{attribute 'keep_dims' requires a constant argument}}
  print(x.mean(alongAxes: [1,2,3], keepingDimensions: someBool))
}

public func shapeError() {
  // expected-error @+1 {{tensor literal should have 9 scalars for this shape, but has 8}}
  let _ = Tensor<Float>(shape: [1, 3, 3, 1],
                        scalars: [0, 1, 0, 1, 1, 1, 0, 1])
}


class ClassTest {
  // expected-error @+1 {{GraphGen cannot lower a 'send' to the host yet}}
  var w = Tensor<Float>(zeros: [1, 2])  // expected-warning {{value implicitly copied to the host}}
  let b = Tensor<Float>(zeros: [1, 2])
  var c : Tensor<Float> { return w }

  func infer(input: Tensor<Float>) -> Tensor<Float> {
    return input
  }
}

public func f() {
  let x = ClassTest()
  let y = x.infer(input: Tensor<Float>(ones: [2, 1]))
  _ = y+y
  // expected-error @+1 {{GraphGen cannot lower a 'receive' from the host yet}}
  _ = x.c+x.b+x.w  // expected-warning 3 {{properties in classes always cause a copy to the accelerator}}

}