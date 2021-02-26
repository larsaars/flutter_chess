package com.lurzapps.chess;

import android.os.Bundle;
import androidx.annotation.Nullable;

import io.flutter.embedding.android.FlutterActivity;

public class MainActivity extends FlutterActivity {
    //private Model model;

    @Override
    public void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        /*try {
            model = Model.newInstance(this);

            new MethodChannel(getFlutterEngine().getDartExecutor().getBinaryMessenger(), "flutter.native/helper").
                    setMethodCallHandler((call, result) -> {
                        if (call.method.equals("predictWithTf")) {
                            //in argument of this method is an flat int array of the shape (1, 8, 8, 12)
                            //this must be converted into a tensor buffer with the data type float32
                            ArrayList<Integer> flatArray = (ArrayList<Integer>) call.arguments;
                            TensorBuffer buffer = TensorBuffer.createFixedSize(new int[]{1, 8, 8, 12}, DataType.FLOAT32);

                            //allocate enough space for the byte array (4 because float in java is 4 byte)
                            ByteBuffer byteBuffer = ByteBuffer.allocate(4 * flatArray.size());
                            //put every fourth position the next float in byte buffer
                            for (int i = 0; i < (flatArray.size() * 4); i += 4)
                                byteBuffer.putFloat(i, flatArray.get(i / 4));
                            //load into tensor buffer
                            buffer.loadBuffer(byteBuffer);

                            //process and get main output
                            TensorBuffer predictionTensor =  model.process(buffer).getOutputFeature0AsTensorBuffer();
                            //this is normally a float but must be typed as double to be able to be sent back as result
                            double predictionDouble = predictionTensor.getFloatArray()[0];

                            //send result back to main flutter application
                            result.success(predictionDouble);
                        }
                    });
        } catch (IOException | NullPointerException e) {
            e.printStackTrace();
        }*/
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        //model.close();
    }
}
