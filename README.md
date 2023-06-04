![](https://github.com/senselogic/SURREAL/blob/master/LOGO/surreal.png)

# Surreal

Unreal C++ code preprocessor.

## Features

* Eliminates redundant and unnecessary code.
* Monitors files changes for instant recompilation.

## Sample

ALightSwitch.upp

```cpp
#pragma once

#include "GameFramework/Actor.h"
#include "LightSwitch.generated.h"

::
#include "BasicClasses.h"
#include "LightSwitch.h"
::

@ BlueprintType
struct FLightSwitchConfiguration
{
    @ EditAnywhere, BlueprintReadWrite, Category="Switch Variables"
    float
        InitialIntensity;

    float
        CurrentIntensity;

    @
    UObject*
        OwnerObject;
};

@
class PROJECTNAME_API ALightSwitch :
    public AActor
{
    public:

    @ VisibleAnywhere, Category = "Switch Components"
    class UPointLightComponent*
        PointLightComponent;

    @ VisibleAnywhere, Category = "Switch Components"
    class USphereComponent*
        SphereComponent;

    ::ALightSwitch(
         )
    {
        DesiredIntensity = 3000.0f;

        PointLightComponent = CreateDefaultSubobject<UPointLightComponent>( TEXT( "PointLightComponent" ) );
        PointLightComponent->Intensity = DesiredIntensity;
        PointLightComponent->bVisible = true;
        RootComponent = PointLightComponent;

        SphereComponent = CreateDefaultSubobject<USphereComponent>( TEXT( "SphereComponent" ) );
        SphereComponent->InitSphereRadius( 250.0f );
        SphereComponent->SetupAttachment( RootComponent );

        SphereComponent->OnComponentBeginOverlap.AddDynamic( this, &ALightSwitch::OnOverlapBegin );
        SphereComponent->OnComponentEndOverlap.AddDynamic( this, &ALightSwitch::OnOverlapEnd );
    }

    @
    void ::OnOverlapBegin(
        class UPrimitiveComponent* overlapped_primitive_component,
        class AActor* other_actor,
        class UPrimitiveComponent* other_primitive_component,
        int32 other_body_index,
        bool is_from_sweep,
        const FHitResult& sweep_hit_result
        )
    {
        if ( other_actor && ( other_actor != this ) && other_primitive_component )
        {
            ToggleLight();
        }
    }

    @
    void ::OnOverlapEnd(
        class UPrimitiveComponent* overlapped_primitive_component = 0,
        class AActor* other_actor = 0,
        class UPrimitiveComponent* other_primitive_component = 0,
        int32 other_body_index = 0
        )
    {
        if ( other_actor && ( other_actor != this ) && other_primitive_component )
        {
            ToggleLight();
        }
    }

    @
    void ::ToggleLight(
        )
    {
        PointLightComponent->ToggleVisibility();
    }

    @ VisibleAnywhere, Category = "Switch Variables"
    float
        DesiredIntensity;
};
```

ALightSwitch.h

```cpp
#pragma once

#include "GameFramework/Actor.h"
#include "LightSwitch.generated.h"

USTRUCT(BlueprintType)
struct FLightSwitchConfiguration
{
    GENERATED_BODY()

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="Switch Variables")
    float
        InitialIntensity;

    float
        CurrentIntensity;

    UPROPERTY()
    UObject*
        OwnerObject;
};

UCLASS()
class PROJECTNAME_API ALightSwitch :
    public AActor
{
    GENERATED_BODY()

    public:

    UCLASS(VisibleAnywhere, Category = "Switch Components")
    class UPointLightComponent*
        PointLightComponent;

    UCLASS(VisibleAnywhere, Category = "Switch Components")
    class USphereComponent*
        SphereComponent;

    ALightSwitch(
         );

    UFUNCTION()
    void OnOverlapBegin(
        class UPrimitiveComponent* overlapped_primitive_component,
        class AActor* other_actor,
        class UPrimitiveComponent* other_primitive_component,
        int32 other_body_index,
        bool is_from_sweep,
        const FHitResult& sweep_hit_result
        );

    UFUNCTION()
    void OnOverlapEnd(
        class UPrimitiveComponent* overlapped_primitive_component = 0,
        class AActor* other_actor = 0,
        class UPrimitiveComponent* other_primitive_component = 0,
        int32 other_body_index = 0
        );

    UFUNCTION()
    void ToggleLight(
        );

    UPROPERTY(VisibleAnywhere, Category = "Switch Variables")
    float
        DesiredIntensity;
};
```

ALightSwitch.cpp

```cpp
#include "BasicClasses.h"
#include "LightSwitch.h"

ALightSwitch::ALightSwitch(
     )
{
    DesiredIntensity = 3000.0f;

    PointLightComponent = CreateDefaultSubobject<UPointLightComponent>( TEXT( "PointLightComponent" ) );
    PointLightComponent->Intensity = DesiredIntensity;
    PointLightComponent->bVisible = true;
    RootComponent = PointLightComponent;

    SphereComponent = CreateDefaultSubobject<USphereComponent>( TEXT( "SphereComponent" ) );
    SphereComponent->InitSphereRadius( 250.0f );
    SphereComponent->SetupAttachment( RootComponent );

    SphereComponent->OnComponentBeginOverlap.AddDynamic( this, &ALightSwitch::OnOverlapBegin );
    SphereComponent->OnComponentEndOverlap.AddDynamic( this, &ALightSwitch::OnOverlapEnd );
}

void ALightSwitch::OnOverlapBegin(
    class UPrimitiveComponent* overlapped_primitive_component,
    class AActor* other_actor,
    class UPrimitiveComponent* other_primitive_component,
    int32 other_body_index,
    bool is_from_sweep,
    const FHitResult& sweep_hit_result
    )
{
    if ( other_actor && ( other_actor != this ) && other_primitive_component )
    {
        ToggleLight();
    }
}

void ALightSwitch::OnOverlapEnd(
    class UPrimitiveComponent* overlapped_primitive_component,
    class AActor* other_actor,
    class UPrimitiveComponent* other_primitive_component,
    int32 other_body_index
    )
{
    if ( other_actor && ( other_actor != this ) && other_primitive_component )
    {
        ToggleLight();
    }
}

void ALightSwitch::ToggleLight(
    )
{
    PointLightComponent->ToggleVisibility();
}
```

## Syntax

* `@` : decorator
* `::`...`(` : implementation method
* `::` ... `::` : implementation code

## Limitations

* Requires well indented code with function arguments on separate lines.

## Installation

Install the [DMD 2 compiler](https://dlang.org/download.html) (using the MinGW setup option on Windows).

Build the executable with the following command line :

```bash
dmd -m64 surreal.d
```

## Command line

```
surreal [options] <FOLDER>
surreal [options] <INPUT_FOLDER> <OUTPUT_FOLDER>
surreal [options] <SCRIPT_FOLDER> <DECLARATION_FOLDER> <IMPLEMENTATION_FOLDER>
```

### Options

```
--extension <script-extension> <declaration-extension> <implementation-extension> : define file extensions
--create : create the output folders if needed
--watch : watch the script files for modifications
--pause 500 : time to wait before checking the script files again
```

### Examples

```bash
surreal --create UPP/ H/ CPP/
```

```bash
surreal --extension .upp .h .cpp --create --watch UPP/ H/ CPP/
```

## Version

0.1

## Author

Eric Pelzer (ecstatic.coder@gmail.com).

## License

This project is licensed under the GNU General Public License version 3.

See the [LICENSE.md](LICENSE.md) file for details.
